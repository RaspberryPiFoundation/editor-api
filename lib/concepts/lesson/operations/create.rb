# frozen_string_literal: true

class Lesson
  class Create
    class << self
      def call(lesson_params:)
        response = OperationResponse.new
        response[:lesson] = build_lesson(lesson_params)
        response[:lesson].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error creating lesson: #{e}"
        response
      end

      private

      def build_lesson(lesson_hash)
        new_lesson = Lesson.new(lesson_hash.except(:project_attributes))
        project_params = lesson_hash[:project_attributes].merge({ user_id: lesson_hash[:user_id] })
        project_creation_response = Project::Create.call(project_hash: project_params)
        new_lesson.project = project_creation_response[:project]
        new_lesson
      end
    end
  end
end
