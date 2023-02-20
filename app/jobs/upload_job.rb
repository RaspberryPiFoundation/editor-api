# frozen_string_literal: true

require 'open-uri'
require 'project_importer'

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
    repository = payload[:repository][:name]
    owner = payload[:repository][:owner][:name]
    response = GitHub::Client.query ProjectContentQuery, variables: {repository: repository, owner: owner, expression: "#{ENV.fetch('GITHUB_WEBHOOK_REF')}:en/code"}
    response.data.repository.object.entries.each do |project_dir|
      components = []
      images = []

      project_dir.object.entries.each do |file|
        if file.name == 'project_config.yml'
          @proj_config = YAML.safe_load(file.object.text)
        elsif file.object.text
          name = file.name.chomp(file.extension)
          extension = file.extension[1..-1]
          content = file.object.text
          default = file.name == 'main.py'
          components << {name: name, extension: extension, content: content, default: default}
        else
          filename = file.name
          directory = project_dir.name
          url = "https://github.com/#{owner}/#{repository}/raw/#{ENV.fetch('GITHUB_WEBHOOK_REF')}/en/code/#{directory}/#{filename}"
          images << {filename: filename, io: URI.parse(url).open}
        end
      end

      project_importer = ProjectImporter.new(name: @proj_config['NAME'], identifier: @proj_config['IDENTIFIER'],
        type: @proj_config['TYPE'] ||= 'python', components: components, images: images)
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
