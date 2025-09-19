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

  class ValidateBatch
    class << self
      def call(school:, students:, token:)
        response = OperationResponse.new
        validate_batch(school:, students:, token:)
        response
      rescue ValidationError => e
        response[:error] = e.errors
        response[:error_type] = :validation_error
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error creating school students: #{e}"
        response[:error_type] = :standard_error
        response
      end

      private

      def validate_batch(school:, students:, token:)
        decrypted_students = decrypt_students(students)
        ProfileApiClient.validate_school_students(token:, students: decrypted_students, school_id: school.id)
      rescue ProfileApiClient::Student422Error => e
        handle_student422_error(e.errors)
      end

      def decrypt_students(students)
        students.deep_dup.each do |student|
          student[:password] = DecryptionHelpers.decrypt_password(student[:password]) if student[:password].present?
        end
      end

      # This method converts the error structure returned by Profile (an array of error objects) to
      # the structure expected by the React front-end, which is a hash with the structure:
      #
      # username => [array of error codes]
      #
      # The front end will translate the error codes into user-readable error messages.
      def handle_student422_error(errors)
        formatted_errors = errors.each_with_object({}) do |error, hash|
          username = error['username'] || error['path']

          hash[username] ||= []
          hash[username] << error['errorCode']

          # Ensure uniqueness to avoid repeat errors with duplicate usernames
          hash[username] = hash[username].uniq
        end

        raise ValidationError, formatted_errors unless formatted_errors.nil? || formatted_errors.blank?
      end
    end
  end
end
