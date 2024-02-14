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

      def invite_teacher(school, school_teacher_params, token)
        email_address = school_teacher_params.fetch(:email_address)

        raise ArgumentError, "email address '#{email_address}' is invalid" unless EmailValidator.valid?(email_address)

        ProfileApiClient.invite_school_teacher(token:, email_address:, organisation_id: school.id)
      end
    end
  end
end
