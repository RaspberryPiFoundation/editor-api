# frozen_string_literal: true

class School
  class Create
    LOCK_NAMESPACE = Zlib.crc32(name)

    class << self
      def call(school_params:, creator_id:, token:)
        response = OperationResponse.new
        response[:school] = build_school(school_params.merge!(creator_id:))

        School.transaction do
          # Serialise concurrent creates by the same creator.
          # The loser blocks here until the winner's transaction commits,
          # so its uniqueness validation sees the winner's school
          # rather than hitting the partial unique index on creator_id.
          acquire_advisory_lock_for_creator(creator_id)
          response[:school].save!

          SchoolOnboardingService.new(response[:school]).onboard(token:)
        end

        response
      rescue ProfileApiClient::UnauthorizedError => e
        # Do not log noise to sentry.
        # TODO: consider returning a separate error here to distinguish from other errors and return 401 from the API, not 422
        Rails.logger.warn { "Failed to onboard school #{response[:school]&.id}: user is unauthorized" }
        failure(response, e)
      rescue ActiveRecord::RecordInvalid => e
        # A double submit loses the advisory lock race and fails the creator_id
        # uniqueness validation as expected, so keep it out of Sentry.
        Sentry.capture_exception(e) unless response[:school]&.errors&.of_kind?(:creator_id, :taken)
        failure(response, e)
      rescue StandardError => e
        Sentry.capture_exception(e)
        failure(response, e)
      end

      private

      def acquire_advisory_lock_for_creator(creator_id)
        lock_key = Zlib.crc32("#{School::Create::LOCK_NAMESPACE}:#{creator_id}")
        School.connection.execute("SELECT pg_advisory_xact_lock(#{lock_key})")
      end

      def failure(response, error)
        school_errors = response[:school]&.errors
        response[:error] = school_errors&.presence || [error.message]
        response[:error_types] = school_errors&.details
        response
      end

      def build_school(school_params)
        School.new(school_params)
      end
    end
  end
end
