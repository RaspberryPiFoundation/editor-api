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
        if response[:feedback].nil?
          response[:error] = "Error creating feedback #{e}"
        else
          errors = response[:feedback].errors.full_messages.join(',')
          response[:error] = "Error creating feedback: #{errors}"
        end
        response
      end

      private

      def build_feedback(feedback_hash)
        project = Project.find_by(identifier: feedback_hash[:identifier])
        school_project = project&.school_project
        if school_project.nil?
          raise "School project not found for identifier: #{feedback_hash[:identifier]}"
        end
        # replace identifier with school_project_id
        feedback_hash[:school_project_id] = school_project.id
        feedback_hash.delete(:identifier)
        new_feedback = Feedback.new(feedback_hash)
        new_feedback
      end
    end
  end
end