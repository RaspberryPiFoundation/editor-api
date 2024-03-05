# frozen_string_literal: true

class Lesson
  class Create
    class << self
      def call(lesson_params:)
        response = OperationResponse.new
        response[:lesson] = Lesson.new(lesson_params)
        response[:lesson].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        errors = response[:lesson].errors.full_messages.join(',')
        response[:error] = "Error creating lesson: #{errors}"
        response
      end
    end
  end
end
