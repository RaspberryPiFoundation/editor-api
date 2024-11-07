# frozen_string_literal: true

module SchoolStudent
  class CreateBatch
    class << self
      def call(school:, school_students_params:, token:, user_id:)
        response = OperationResponse.new
        response[:job_id] = create_batch(school, school_students_params, token, user_id)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:errors] = JSON.parse(e.message)
        response
      end

      private

      def create_batch(school, students, token, _user_id)
        students = Array(students).map do |student|
          student[:password] = DecryptionHelpers.decrypt_password(student[:password])
          student
        end

        validate(school:, students:, token:)

        job = CreateStudentsJob.attempt_perform_later(school_id: school.id, students:, token:, user_id:)
        job&.job_id
      end

      def validate(school:, students:, token:)
        begin
          ProfileApiClient.create_school_students(token:, students:, school_id: school.id, preflight: true)
        rescue ProfileApiClient::Student422Error => e
          errors = JSON.parse(e.message).each_with_object({}) do |error, hash|
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
        end

        raise ArgumentError, errors.to_json unless errors&.empty?
      end
    end
  end
end
