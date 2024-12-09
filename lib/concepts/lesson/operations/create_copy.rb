# frozen_string_literal: true

class Lesson
  class CreateCopy
    class << self
      def call(lesson:, lesson_params:)
        response = OperationResponse.new
        response[:lesson] = build_copy(lesson, lesson_params)
        response[:lesson].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        errors = response[:lesson].errors.full_messages.join(',')
        response[:error] = "Error creating copy of lesson: #{errors}"
        response
      end

      private

      # TODO: copy projects
      def build_copy(lesson, lesson_params)
        lesson_copy = Lesson.new(parent: lesson, name: lesson.name, description: lesson.description)
        lesson_copy.assign_attributes(lesson_params)

        project_params = lesson.project.attributes.except('id', 'identifier')
        project_copy = Project.new(project_params)
        project_copy.user_id = lesson_params[:user_id]
        project_copy.lesson_id = lesson_copy.id

        lesson.project.images.each do |image|
          project_copy.images.attach(image.blob)
        end

        lesson.project.components.each do |component|
          project_copy.components.build({ name: component.name, extension: component.extension, content: component.content })
        end

        lesson_copy.project = project_copy
        lesson_copy
      end
    end
  end
end
