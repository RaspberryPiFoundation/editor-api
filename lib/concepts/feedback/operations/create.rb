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
        pp 'there was an error'
        pp 'the error was:'
        pp e
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
        puts 'building feedback from hash:'
        puts feedback_hash.inspect
        project = Project.find_by(identifier: feedback_hash[:project_id])
        school_project = project&.school_project
        if school_project.nil?
          raise "School project not found for identifier: #{feedback_hash[:project_id]}"
        end
        # replace identifier with school_project_id
        feedback_hash[:school_project_id] = school_project.id
        feedback_hash.delete(:project_id)
        puts 'the feedback hash is now:'
        puts feedback_hash.inspect
        puts 'building feedback object'
        new_feedback = Feedback.new(feedback_hash)
        new_feedback
      end
    end
  end
end