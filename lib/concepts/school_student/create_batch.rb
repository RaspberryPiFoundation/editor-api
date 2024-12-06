# frozen_string_literal: true

module SchoolStudent
  class Error < StandardError; end

  class ValidationError < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super()
    end
  end

  class CreateBatch
    class << self
      def call(school:, school_students_params:, token:, user_id:)
        response = OperationResponse.new
        response[:job_id] = create_batch(school, school_students_params, token, user_id)
        response
      rescue ValidationError => e
        response[:error] = e.errors
        response[:error_type] = :validation_error
        response
      rescue ConcurrencyExceededForSchool => e
        response[:error] = e
        response[:error_type] = :job_concurrency_error
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error creating school students: #{e}"
        response[:error_type] = :standard_error
        response
      end

      private

      def create_batch(school, students, token, user_id)
        # Ensure that nil values are empty strings, else Profile will swallow validations
        students = students.map do |student|
          student.transform_values { |value| value.nil? ? '' : value }
        end

        validate(school:, students:, token:)

        job = CreateStudentsJob.attempt_perform_later(school_id: school.id, students:, token:, user_id:)
        job&.job_id
      end

      def validate(school:, students:, token:)
        decrypted_students = decrypt_students(students)
        ProfileApiClient.create_school_students(token:, students: decrypted_students, school_id: school.id, preflight: true)
      rescue ProfileApiClient::Student422Error => e
        handle_student422_error(e.errors)
      end

      def decrypt_students(students)
        students.deep_dup.each do |student|
          student[:password] = DecryptionHelpers.decrypt_password(student[:password]) if student[:password].present?
        end
      end

      def handle_student422_error(errors)
        formatted_errors = errors.each_with_object({}) do |error, hash|
          username = error['username'] || error['path']
          field = error['path'].split('.').last

          hash[username] ||= []
          hash[username] << I18n.t(
            "validations.school_student.#{error['errorCode'].underscore}",
            field:,
            default: error['message']
          )

          # Ensure uniqueness to avoid repeat errors with duplicate usernames
          hash[username] = hash[username].uniq
        end

        raise ValidationError, formatted_errors unless formatted_errors.nil? || formatted_errors.blank?
      end
    end
  end
end
