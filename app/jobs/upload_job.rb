# frozen_string_literal: true

require 'open-uri'
require 'github_api'

class UploadJob < ApplicationJob
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

  def perform(payload)
    modified_locales(payload).each do |locale|
      projects_data = load_projects_data(locale, repository(payload), owner(payload))
      if projects_data.data.repository&.object.nil?
        Rails.logger.warn 'Build skipped, does the repo exist?'
        break
      end

      projects_data.data.repository.object.entries.each do |project_dir|
        project = format_project(project_dir, locale, repository(payload), owner(payload))
        if @skip_job
          Rails.logger.warn "Build skipped for #{project[:name]}"
          next
        end

        project_importer = ProjectImporter.new(**project)
        project_importer.import!
      end
    rescue StandardError => e
      Sentry.capture_exception(e)
      raise e # Re-raise the error to make the job fail
    end
  end

  private

  def modified_locales(payload)
    commits = payload[:commits]
    modified_paths = commits.map { |commit| commit[:added] | commit[:modified] | commit[:removed] }.flatten
    modified_paths.map { |path| path.split('/')[0] }.uniq
  end

  def load_projects_data(locale, repository, owner)
    response = GithubApi::Client.query(
      ProjectContentQuery,
      variables: { repository:, owner:, expression: "#{ENV.fetch('GITHUB_WEBHOOK_REF')}:#{locale}/code" }
    )

    if response.data.errors.any?
      error_messages = response.data.errors.messages.map { |error| error }
      error_details = response.data.errors.details.map { |error| error }
      error_type = error_details.dig(0, 1, 0, 'type')

      # Handle NOT_FOUND errors as a special case, as this can happen when the repo is first created
      raise GraphQL::Client::Error, "GraphQL query failed with errors: #{error_messages}. Details: #{error_details}" unless error_type == 'NOT_FOUND'
    end

    response
  end

  def format_project(project_dir, locale, repository, owner)
    components = []
    images = []
    proj_config = {}

    data = project_dir.object
    raise InvalidDirectoryStructureError, "The directory structure is incorrect and the job can't be processed." unless data.respond_to?(:entries)

    data.entries.each do |file|
      if file.name == 'project_config.yml'
        proj_config = YAML.safe_load(file.object.text, symbolize_names: true)

        # Skip if build is set to false (for backwards compatibility the build must happen if the key is not present)
        if proj_config[:build] == false
          @skip_job = true
          break
        end
      elsif file.object.text
        components << component(file)
      else
        images << image(file, project_dir, locale, repository, owner)
      end
    end

    { **proj_config, locale:, components:, images: }
  end

  def component(file)
    name = file.name.chomp(file.extension)
    extension = file.extension[1..]
    content = file.object.text
    default = file.name == 'main.py'
    { name:, extension:, content:, default: }
  end

  def image(file, project_dir, locale, repository, owner)
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
end

class InvalidDirectoryStructureError < StandardError; end
