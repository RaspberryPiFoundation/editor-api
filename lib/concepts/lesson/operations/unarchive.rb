# frozen_string_literal: true

class Lesson
  class Unarchive
    class << self
      def call(lesson:)
        response = OperationResponse.new
        lesson.unarchive!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error unarchiving lesson: #{e}"
        response
      end
    end
  end
end
