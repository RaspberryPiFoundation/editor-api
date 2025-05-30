# frozen_string_literal: true

class Lesson
  class CreateFromProject
    class << self
      def call(lesson_params:, remix_origin:)
        response = OperationResponse.new
        response[:lesson] = build_lesson_from_project(lesson_params, remix_origin)
        response[:lesson].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        errors = response[:lesson].errors.full_messages.join(',')
        response[:error] = "Error creating lesson from project: #{errors}"
        response
      end

      private

      def build_lesson_from_project(lesson_params, _remix_origin)
        project = Project.find_by(identifier: lesson_params[:project_identifier])
        lesson = Lesson.new(
          name: project.name
        )
        lesson.assign_attributes(lesson_params.except(:project_identifier))
        lesson.project = project
        lesson
      end
    end
  end
end
