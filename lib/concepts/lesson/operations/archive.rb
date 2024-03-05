# frozen_string_literal: true

class Lesson
  class Archive
    class << self
      def call(lesson:)
        response = OperationResponse.new
        lesson.archive!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error archiving lesson: #{e}"
        response
      end
    end
  end
end
