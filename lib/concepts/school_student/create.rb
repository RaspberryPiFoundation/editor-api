# frozen_string_literal: true

module SchoolStudent
  class Create
    class << self
      def call(school:, school_student_params:, token:)
        response = OperationResponse.new
        response[:student_id] = create_student(school, school_student_params, token)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = e.to_s
        response
      end

      private

      def create_student(school, school_student_params, token)
        school_id = school.id
        username = school_student_params.fetch(:username)
        encrypted_password = school_student_params.fetch(:password)
        password = DecryptionHelpers.decrypt_password(encrypted_password)
        name = school_student_params.fetch(:name)

        validate(
          username:,
          password:,
          name:,
          school: (FeatureFlags.immediate_school_onboarding? ? nil : school)
        )

        response = ProfileApiClient.create_school_student(token:, username:, password:, name:, school_id:)
        user_id = response[:created].first
        Role.student.create!(school:, user_id:)
        user_id
      end

      def validate(username:, password:, name:, school: nil)
        raise ArgumentError, "username '#{username}' is invalid" if username.blank?
        raise ArgumentError, "password '#{password}' is invalid" if password.size < 8
        raise ArgumentError, "name '#{name}' is invalid" if name.blank?

        return unless school
        raise ArgumentError, 'school must be verified' unless school.verified?
      end
    end
  end
end
