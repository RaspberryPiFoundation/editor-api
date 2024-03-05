# frozen_string_literal: true

class Lesson
  class Update
    class << self
      def call(lesson:, lesson_params:)
        response = OperationResponse.new
        response[:lesson] = lesson
        response[:lesson].assign_attributes(lesson_params)
        response[:lesson].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        errors = response[:lesson].errors.full_messages.join(',')
        response[:error] = "Error updating lesson: #{errors}"
        response
      end
    end
  end
end
