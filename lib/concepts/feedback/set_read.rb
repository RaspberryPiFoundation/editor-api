# frozen_string_literal: true

class Feedback
  class SetRead
    class << self
      def call(feedback:)
        response = OperationResponse.new
        response[:feedback] = feedback
        response[:feedback].read_at = Time.current
        response[:feedback].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = response[:feedback]&.errors
        response
      end
    end
  end
end
