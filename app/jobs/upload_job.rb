# frozen_string_literal: true

class UploadJob < ApplicationJob
  ProjectContentQuery = GitHub::Client.parse <<-'GRAPHQL'
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
    puts 'hello world'
    # pp modified_code_projects(payload)
    response = GitHub::Client.query ProjectContentQuery, variables: {repository: payload[:repository][:name], owner: payload[:repository][:owner][:name], expression: "#{ENV.fetch('GITHUB_WEBHOOK_REF')}:en/code"}
    response.data.repository.object.entries.each do |project_dir|
      components = []
      images = []

      project_dir.object.entries.each do |file|
        if file.name == 'proj_config.yml'
          # it's the config
          @proj_config = YAML.safe_load(file.object.text)

        elsif !file.object.isBinary
          # It's a component
          name = file.name
          extension = file.extension
          content = file.object.text
          default = file.name == 'main.py'
          components << {name:, extension:, content:, default:}
        else
          # It's an image
          name = file.name
          images << {name:}
        end
      end
      project_importer = ProjectImporter.new(name: @proj_config['NAME'], identifier: @proj_config['IDENTIFIER'],
        type: @proj_config['TYPE'] ||= 'python', components:, images:)
        project_importer.import!
    end
  end

  private
  def modified_code_projects(payload)
    commits = payload[:commits]
    modified_paths = commits.map { |commit| commit[:added] | commit[:modified] | commit[:removed] }.flatten
    modified_paths.filter { |path| path.start_with?('en/code') }.map { |path|
      split_path = path.split('/')
      "en/code/#{split_path[2]}"
    }
  end
end
