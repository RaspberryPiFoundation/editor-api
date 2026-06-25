# frozen_string_literal: true

class SchoolEmailDomain
  class Create
    LOCK_NAMESPACE = Zlib.crc32(name) # convert the class name into a 32-bit int to derive the namespace for our advisory lock

    class << self
      def call(school:, domain:, token:)
        response = OperationResponse.new
        response[:school_email_domain] = nil
        response[:school_email_domain] = build_domain(school, domain)

        SchoolEmailDomain.transaction do
          response[:school_email_domain].save!
          acquire_advisory_lock_for_school(school)
          update_profile(school, token)
        end
        response
      rescue ActiveRecord::RecordInvalid => e
        record = response[:school_email_domain] || e.record
        response[:error] = record.errors.full_messages.join(', ')
        response[:error_code] = domain_error_code(record)
        response
      rescue ActiveRecord::RecordNotUnique
        record = response[:school_email_domain]
        record.errors.add(:domain, :taken)
        response[:error] = record.errors.full_messages.join(', ')
        response[:error_code] = 'taken'
        response
      rescue StandardError => e
        Sentry.capture_exception(e) # Send unexpected/Profile errors to Sentry
        response[:error] = e.message
        response[:error_code] = 'profile_sync_failed'
        response
      end

      private

      def acquire_advisory_lock_for_school(school)
        lock_key = Zlib.crc32("#{LOCK_NAMESPACE}:#{school.id}")
        SchoolEmailDomain.connection.execute("SELECT pg_advisory_xact_lock(#{lock_key})")
      end

      def build_domain(school, domain)
        school.school_email_domains.build(domain:)
      end

      def update_profile(school, token)
        school_email_domains = school.school_email_domains.order(:created_at).pluck(:domain)
        ProfileApiClient.update_school_email_domains(token:, school_id: school.id, school_email_domains:)
      end

      def domain_error_code(record)
        record.errors.details[:domain].first.fetch(:error).to_s
      end
    end
  end
end
