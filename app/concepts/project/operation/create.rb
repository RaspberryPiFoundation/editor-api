# frozen_string_literal: true

require 'operation_response'

class Project
  module Operation
    class Create
      DEFAULT_COMPONENT = {
        name: 'main',
        extension: 'py',
        default: true,
        index: 0
      }.freeze
      DEFAULT_PROJECT = {
        type: 'python',
        name: 'Untitled project',
        components: [DEFAULT_COMPONENT],
        image_list: []
      }.freeze

      class << self
        def call(user_id:, params:)
          response = OperationResponse.new

          project_hash = DEFAULT_PROJECT.merge(
            params.to_hash.deep_transform_keys do |key|
              key.to_sym
            rescue StandardError
              key
            end
          )

          response[:project] = build_project(project_hash, user_id)
          response[:project].save!
          response
        rescue StandardError => e
          Sentry.capture_exception(e)
          response[:error] = 'Error creating project'
          response
        end

        private

        def build_project(project_hash, user_id)
          new_project = Project.new(project_type: project_hash[:type], user_id: user_id, name: project_hash[:name])
          new_project.components.build(project_hash[:components])

          project_hash[:image_list].each do |image|
            new_project.images.attach(image.blob)
          end

          new_project
        end
      end
    end
  end
end
