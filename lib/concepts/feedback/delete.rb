# frozen_string_literal: true

class Feedback
  class Delete
    class << self
      def call(feedback_id:)
        response = OperationResponse.new
        delete_feedback(feedback_id)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error deleting feedback: #{e}"
        response
      end

      private

      def delete_feedback(feedback_id)
        feedback = Feedback.find(feedback_id)
        feedback.destroy!
      end
    end
  end
end
