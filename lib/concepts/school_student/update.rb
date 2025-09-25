# frozen_string_literal: true

module SchoolStudent
  class Error < StandardError; end

  class SSOStudentUpdateError < StandardError
    attr_reader :error

    def initialize(errors)
      @error = errors
      super
    end
  end

  class Update
    class << self
      def call(school:, student_id:, school_student_params:, token:)
        response = OperationResponse.new
        update_student(school, student_id, school_student_params, token)
        response
      rescue SSOStudentUpdateError => e
        Sentry.capture_exception(e)
        response[:error] = e.message
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = e.to_s
        response
      end

      private

      def update_student(school, student_id, school_student_params, token)
        username = school_student_params.fetch(:username, nil)
        name = school_student_params.fetch(:name, nil)
        password = school_student_params.fetch(:password, nil)
        password = DecryptionHelpers.decrypt_password(password) if password.present?

        validate(username:, password:, name:)

        # Prevent updating SSO students (students with email present but no username)
        # TODO: Update to use school_student() when profile returns the email field from that endpoint
        students = ProfileApiClient.list_school_students(
          school_id: school.id,
          student_ids: [student_id],
          token: token
        )

        student = students.first
        raise SSOStudentUpdateError, 'Updating SSO students is not allowed' if student.sso?

        ProfileApiClient.update_school_student(
          token:, school_id: school.id, student_id:, username:, password:, name:
        )
      end

      def validate(username:, password:, name:)
        raise ArgumentError, "username '#{username}' is invalid" if !username.nil? && username.blank?
        raise ArgumentError, "password '#{password}' is invalid" if !password.nil? && password.size < 8
        raise ArgumentError, "name '#{name}' is invalid" if !name.nil? && name.blank?
      end
    end
  end
end
