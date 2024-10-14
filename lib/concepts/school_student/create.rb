# frozen_string_literal: true

module SchoolStudent
  class Create
    class << self
      def call(school:, school_student_params:, token:)
        response = OperationResponse.new
        create_student(school, school_student_params, token)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error creating school student: #{e}"
        response
      end

      private

      def create_student(school, school_student_params, token)
        username = school_student_params.fetch(:username)
        password = school_student_params.fetch(:password)
        name = school_student_params.fetch(:name)

        validate(username:, password:, name:)
        # TODO: Do the preflight checks here

        students = [{ username:, password:, name: }]

        CreateStudentsJob.attempt_perform_later(school_id: school.id, students:, token:)
      end

      def validate(username:, password:, name:)
        # Just ensure we have values, otherwise leave validation to the API
        raise ArgumentError, "username '#{username}' is invalid" if username.blank?
        raise ArgumentError, "password '#{password}' is invalid" if password.blank?
        raise ArgumentError, "name '#{name}' is invalid" if name.blank?
      end
    end
  end
end
