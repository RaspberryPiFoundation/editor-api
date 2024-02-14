# frozen_string_literal: true

module SchoolTeacher
  class Invite
    class << self
      def call(school:, school_teacher_params:, token:)
        response = OperationResponse.new
        response[:school_teacher] = invite_teacher(school, school_teacher_params, token)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error inviting school teacher: #{e}"
        response
      end

      private

      def invite_teacher(school, school_teacher_params, token)
        organisation_id = school.id
        email_address = school_teacher_params.fetch(:email_address)

        raise ArgumentError, "email address '#{email_address}' is invalid" unless EmailValidator.valid?(email_address)

        response = ProfileApiClient.invite_school_teacher(token:, email_address:, organisation_id:)
        user_id = response.fetch(:id)

        User.from_userinfo(ids: user_id).first
      end
    end
  end
end
