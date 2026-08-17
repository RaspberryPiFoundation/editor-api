# frozen_string_literal: true

class School
  class Create
    class << self
      def call(school_params:, creator_id:, token:)
        response = OperationResponse.new
        response[:school] = build_school(school_params.merge!(creator_id:))

        School.transaction do
          response[:school].save!

          SchoolOnboardingService.new(response[:school]).onboard(token:)
        end

        response
      rescue ProfileApiClient::UnauthorizedError => e
        # Do not log noise to sentry.
        # TODO: consider returning a separate error here to distinguish from other errors and return 401 from the API, not 422
        Rails.logger.warn { "Failed to onboard school #{response[:school].id}: user is unauthorized" }
        failure(response, e)
      rescue StandardError => e
        Sentry.capture_exception(e)
        failure(response, e)
      end

      private

      def failure(response, error)
        response[:error] = response[:school].errors.presence || [error.message]
        response[:error_types] = response[:school].errors.details
        response
      end

      def build_school(school_params)
        School.new(school_params)
      end
    end
  end
end
