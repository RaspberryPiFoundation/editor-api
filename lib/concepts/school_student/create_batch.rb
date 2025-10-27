# frozen_string_literal: true

module SchoolStudent
  class Error < StandardError; end

  class ConcurrencyExceededForSchool < StandardError; end

  class CreateBatch
    class << self
      def call(school:, school_students_params:, token:)
        response = OperationResponse.new
        response[:job_id] = create_batch(school, school_students_params, token)
        response
      rescue ConcurrencyExceededForSchool => e
        response[:error] = e
        response[:error_type] = :job_concurrency_error
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = e.to_s
        response[:error_type] = :standard_error
        response
      end

      private

      def create_batch(school, students, token)
        job = CreateStudentsJob.attempt_perform_later(school_id: school.id, students:, token:)
        job&.job_id
      end
    end
  end
end
