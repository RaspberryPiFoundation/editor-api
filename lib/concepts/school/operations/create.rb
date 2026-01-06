# frozen_string_literal: true

class School
  class Create
    class << self
      def call(school_params:, creator_id:, token:)
        response = OperationResponse.new
        response[:school] = build_school(school_params.merge!(creator_id:))

        School.transaction do
          response[:school].save!

          # TODO: Remove this conditional once the feature flag is retired
          SchoolOnboardingService.new(response[:school]).onboard(token:) if FeatureFlags.immediate_school_onboarding?
        end

        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = response[:school].errors.presence || [e.message]
        response[:error_types] = response[:school].errors.details

        response
      end

      private

      def build_school(school_params)
        School.new(school_params)
      end
    end
  end
end
