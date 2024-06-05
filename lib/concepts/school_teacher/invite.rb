# frozen_string_literal: true

module SchoolTeacher
  class Invite
    class << self
      def call(school:, school_teacher_params:, token:)
        response = OperationResponse.new
        invite_teacher(school, school_teacher_params, token)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error inviting school teacher: #{e}"
        response
      end

      private

      def invite_teacher(school, school_teacher_params, _token)
        email_address = school_teacher_params.fetch(:email_address)

        raise ArgumentError, 'school is not verified' unless school.verified_at
        raise ArgumentError, "email address '#{email_address}' is invalid" unless EmailValidator.valid?(email_address)

        Invitation.create(school:, email_address:)
      end
    end
  end
end
