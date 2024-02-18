# frozen_string_literal: true

class Lesson
  class Create
    class << self
      def call(school:, school_class:, lesson_params:, current_user:)
        response = OperationResponse.new
        response[:lesson] = build_lesson(school, school_class, lesson_params, current_user)
        response[:lesson].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        errors = response[:lesson].errors.full_messages.join(',')
        response[:error] = "Error creating lesson: #{errors}"
        response
      end

      private

      # TODO
      def build_lesson(school, school_class, lesson_params, current_user)
        lesson = Lesson.new(lesson_params)
        lesson.user_id = current_user.id
        lesson
      end
    end
  end
end
