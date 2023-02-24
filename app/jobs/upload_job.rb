# frozen_string_literal: true

require 'open-uri'
require 'project_importer'
require 'github_api'

class UploadJob < ApplicationJob
  ProjectContentQuery = GithubApi::Client.parse <<-'GRAPHQL'
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
    repository = payload[:repository][:name]
    owner = payload[:repository][:owner][:name]
    projects_data = load_projects_data(repository, owner)

    projects_data.data.repository.object.entries.each do |project_dir|
      project = format_project(project_dir, repository, owner)
      project_importer = ProjectImporter.new(**project)
      project_importer.import!
    end
  end

  private

  def load_projects_data(repository, owner)
    GithubApi::Client.query(
      ProjectContentQuery,
      variables: { repository:, owner:, expression: "#{ENV.fetch('GITHUB_WEBHOOK_REF')}:en/code" }
    )
  end

  def format_project(project_dir, repository, owner)
    components = []
    images = []
    project_dir.object.entries.each do |file|
      if file.name == 'project_config.yml'
        @proj_config = YAML.safe_load(file.object.text, symbolize_names: true)
      elsif file.object.text
        components << component(file)
      else
        images << image(file, project_dir, repository, owner)
      end
    end
    { **@proj_config, components:, images: }
  end

  def component(file)
    name = file.name.chomp(file.extension)
    extension = file.extension[1..]
    content = file.object.text
    default = file.name == 'main.py'
    { name:, extension:, content:, default: }
  end

  def image(file, project_dir, repository, owner)
    filename = file.name
    directory = project_dir.name
    url = "https://github.com/#{owner}/#{repository}/raw/#{ENV.fetch('GITHUB_WEBHOOK_REF')}/en/code/#{directory}/#{filename}"
    { filename:, io: URI.parse(url).open }
  end
end
