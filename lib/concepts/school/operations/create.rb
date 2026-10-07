# frozen_string_literal: true

class School
  class Create
    class << self
      def call(school_params:, owner_id:, token:)
        response = OperationResponse.new

        begin
          response[:school] = nil
          response[:school] = build_school(school_params)

          # Savepoint so failures roll back the school even when called inside an outer transaction (e.g. SchoolImportJob)
          School.transaction(requires_new: true) do
            acquire_advisory_lock_for_owner(owner_id)
            response[:school].save!

            SchoolOnboardingService.new(response[:school]).onboard(owner_id:, token:)
          end

          response
        rescue ProfileApiClient::UnauthorizedError => e
          # Do not log noise to sentry.
          # TODO: consider returning a separate error here to distinguish from other errors and return 401 from the API, not 422
          Rails.logger.warn { "Failed to onboard school #{response[:school].id}: user is unauthorized" }
          failure(response, e)
        rescue ActiveRecord::RecordInvalid => e
          if e.record.is_a?(Role)
            response[:school].errors.merge!(e.record.errors)
          else
            Sentry.capture_exception(e)
          end
          failure(response, e)
        rescue StandardError => e
          Sentry.capture_exception(e)
          failure(response, e)
        end
      end

      private

      def acquire_advisory_lock_for_owner(owner_id)
        lock_key = Zlib.crc32("#{owner_id}:#{name}")
        School.connection.execute("SELECT pg_advisory_xact_lock(#{lock_key})")
      end

      def failure(response, error)
        school = response[:school]
        response[:error] = school&.errors.presence || [error.message]
        response[:error_types] = school&.errors&.details || {}
        response
      end

      def build_school(school_params)
        School.new(school_params)
      end
    end
  end
end
