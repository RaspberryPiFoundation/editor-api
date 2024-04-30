# frozen_string_literal: true

class School
  class Create
    class << self
      def call(school_params:, user_id:, token:)
        response = OperationResponse.new
        response[:school] = build_school(school_params.merge!(user_id:), token)
        response[:school].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = response[:school].errors
        response
      end

      private

      def build_school(school_params, token)
        school = School.new(school_params)

        # TODO: To be removed once we move to a separate organisation_id
        if school.valid_except_for_id?
          response = ProfileApiClient.create_organisation(token:)
          school.id = response&.fetch(:id)
        end

        school
      end
    end
  end
end
