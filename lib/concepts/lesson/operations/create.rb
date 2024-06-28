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
        project_params = lesson_hash[:project_attributes].merge({ user_id: lesson_hash[:user_id],
                                                                  school_id: lesson_hash[:school_id] })
        new_lesson.project = Project.new(project_params)
        new_lesson
      end
    end
  end
end
