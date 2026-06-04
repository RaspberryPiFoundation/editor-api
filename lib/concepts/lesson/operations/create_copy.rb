# frozen_string_literal: true

class Lesson
  class CreateCopy
    class << self
      def call(lesson:, lesson_params:)
        response = OperationResponse.new

        Lesson.transaction do
          response[:lesson] = build_copy(lesson, lesson_params)
          response[:lesson].save!
          copy_scratch_assets(lesson.project, response[:lesson].project)
        end

        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        errors = response[:lesson].errors.full_messages.join(',')
        response[:error] = "Error creating copy of lesson: #{errors}"
        response
      end

      private

      def build_copy(lesson, lesson_params)
        lesson_copy = Lesson.new(parent: lesson, name: lesson.name, description: lesson.description)
        lesson_copy.assign_attributes(lesson_params)

        project_params = { name: lesson_copy.name, user_id: lesson_params[:user_id], lesson_id: lesson_copy.id }
        lesson_copy.project = build_project_copy(lesson.project, project_params)

        lesson_copy
      end

      def build_project_copy(project, project_params)
        project_attributes = project.attributes.except('id', 'identifier', 'created_at', 'updated_at').merge(project_params)
        project_copy = Project.new(project_attributes)

        project.images.each do |image|
          project_copy.images.attach(image.blob)
        end

        project.components.each do |component|
          project_copy.components.build({ name: component.name, extension: component.extension, content: component.content })
        end

        copy_scratch_component(project, project_copy)

        project_copy
      end

      def copy_scratch_component(project, project_copy)
        return unless project.scratch_project? && project.scratch_component

        project_copy.build_scratch_component(content: project.scratch_component.content.deep_dup)
      end

      def copy_scratch_assets(project, project_copy)
        return unless project.scratch_project?

        project.scratch_assets.where(uploaded_user_id: project.user_id).find_each do |scratch_asset|
          next unless scratch_asset.file.attached?

          scratch_asset_copy = project_copy.scratch_assets.create!(
            filename: scratch_asset.filename,
            uploaded_user_id: project_copy.user_id
          )
          scratch_asset_copy.file.attach(scratch_asset.file.blob)
        end
      end
    end
  end
end
