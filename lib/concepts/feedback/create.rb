# frozen_string_literal: true

class Feedback
  class Create
    class << self
      def call(feedback_params:)
        response = OperationResponse.new
        response[:feedback] = build_feedback(feedback_params)
        response[:feedback].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        if response[:feedback].present? && response[:feedback].errors.any?
          errors = response[:feedback]&.errors&.full_messages&.join(',')
          response[:error] = "Error creating feedback: #{errors}"
        else
          response[:error] = "Error creating feedback: #{e.message}"
        end
        response
      end

      private

      def build_feedback(feedback_hash)
        project = Project.find_by(identifier: feedback_hash[:identifier])
        school_project = project&.school_project

        # replace identifier with school_project_id
        feedback_hash[:school_project_id] = school_project&.id
        feedback_hash.delete(:identifier)
        Feedback.new(feedback_hash)
      end
    end
  end
end
