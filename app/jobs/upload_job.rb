# frozen_string_literal: true

require 'open-uri'
require 'github_api'
require 'locales'

class InvalidDirectoryStructureError < StandardError; end
class DataNotFoundError < StandardError; end

class UploadJob < ApplicationJob
  retry_on StandardError, wait: :polynomially_longer, attempts: 3 do |_job, e|
    Sentry.capture_exception(e)
    raise e
  end

  # Don't retry...
  rescue_from DataNotFoundError, InvalidDirectoryStructureError do |e|
    Sentry.capture_exception(e)
    raise e
  end

  VALID_LOCALES = Locales.load_locales.freeze

  @skip_job = false

  ProjectContentQuery = GithubApi::Client.parse <<-GRAPHQL
    query($owner: String!, $repository: String!, $expression: String!) {
      repository(owner: $owner, name: $repository) {
        object(expression: $expression) {
          ... on Tree {
            entries {
              name
              object {
                ... on Tree {
                  entries {
                    name
                    extension
                    object {
                      ... on Blob {
                        text
                        commitResourcePath
                        isBinary
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  GRAPHQL

  PROJECT_CONFIG = 'project_config.yml'

  def perform(payload)
    modified_locales(payload).each do |locale|
      projects_data = load_projects_data(locale, repository(payload), owner(payload))

      # A missing repo just returns nil...
      raise DataNotFoundError, "Data not found in: #{repository(payload)} (with locale: #{locale})" if projects_data.data&.repository&.object.nil?

      projects_data.data.repository.object.entries.each do |project_dir|
        project = format_project(project_dir, locale, repository(payload), owner(payload))
        if @skip_job
          Rails.logger.warn "Build skipped for #{project[:name]}"
          next
        end

        project_importer = ProjectImporter.new(**project)
        project_importer.import!
      end
    end
  end

  private

  def modified_locales(payload)
    commits = payload[:commits]
    modified_paths = commits.map { |commit| commit[:added] | commit[:modified] | commit[:removed] }.flatten
    locales = modified_paths.map { |path| path.split('/')[0] }.uniq
    locales.select { |locale| VALID_LOCALES.include?(locale.to_sym) }
  end

  def load_projects_data(locale, repository, owner)
    response = GithubApi::Client.query(
      ProjectContentQuery,
      variables: { repository:, owner:, expression: "#{ENV.fetch('GITHUB_WEBHOOK_REF')}:#{locale}/code" }
    )

    handle_graphql_errors(response)
    response
  end

  def handle_graphql_errors(response)
    errors = response&.errors || response&.data&.errors
    return if errors.blank?

    raise GraphQL::Client::Error, "GraphQL query failed with errors: #{errors.inspect}"
  end

  def format_project(project_dir, locale, repository, owner)
    data = project_dir.object
    validate_directory_structure(data)

    proj_config_file = data.entries.find { |file| file.name == PROJECT_CONFIG }
    proj_config = YAML.safe_load(proj_config_file.object.text, symbolize_names: true)

    if proj_config[:build] == false
      @skip_job = true
      return proj_config
    end

    files = data.entries.reject { |file| file.name == PROJECT_CONFIG }
    categorized_files = categorize_files(files, project_dir, locale, repository, owner)

    { **proj_config, locale:, **categorized_files }
  end

  def validate_directory_structure(data)
    raise InvalidDirectoryStructureError, 'The directory structure is incorrect and the job can\'t be processed.' unless data.respond_to?(:entries)
  end

  def categorize_files(files, project_dir, locale, repository, owner)
    categories = {
      components: [],
      images: [],
      videos: [],
      audio: []
    }

    files.each do |file|
      mime_type = file_mime_type(file)

      case mime_type
      when /text/ || /application\/javascript/
        categories[:components] << component(file)
      when /image/
        categories[:images] << media(file, project_dir, locale, repository, owner)
      when /video/
        categories[:videos] << media(file, project_dir, locale, repository, owner)
      when /audio/
        categories[:audio] << media(file, project_dir, locale, repository, owner)
      else
        raise "Unsupported file type: #{mime_type}"
      end
    end

    categories
  end

  def component(file)
    name = file.name.chomp(file.extension)
    extension = file.extension[1..]
    content = file.object.text
    default = file.name == 'main.py'
    { name:, extension:, content:, default: }
  end

  def media(file, project_dir, locale, repository, owner)
    filename = file.name
    directory = project_dir.name
    url = "https://github.com/#{owner}/#{repository}/raw/#{ENV.fetch('GITHUB_WEBHOOK_REF')}/#{locale}/code/#{directory}/#{filename}"
    { filename:, io: URI.parse(url).open }
  end

  def repository(payload)
    payload[:repository][:name]
  end

  def owner(payload)
    payload[:repository][:owner][:name]
  end

  def file_mime_type(file)
    Marcel::MimeType.for(file.object, name: file.name)
  end
end
