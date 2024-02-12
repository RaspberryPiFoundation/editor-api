# frozen_string_literal: true

class School
  class Create
    class << self
      def call(school_params:, current_user:)
        response = OperationResponse.new
        response[:school] = build_school(school_params, current_user)
        response[:school].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        errors = response[:school].errors.full_messages.join(',')
        response[:error] = "Error creating school: #{errors}"
        response
      end

      private

      def build_school(school_params, current_user)
        school = School.new(school_params)
        school.owner_id = current_user&.id

        if school.valid_except_for_id?
          response = ProfileApiClient.create_organisation(token: current_user&.token)
          school.id = response&.fetch(:id)
        end

        school
      end
    end
  end
end
