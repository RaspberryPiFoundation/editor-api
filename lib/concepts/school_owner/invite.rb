# frozen_string_literal: true

module SchoolOwner
  class Invite
    class << self
      def call(school:, school_owner_params:, token:)
        response = OperationResponse.new
        response[:school_owner] = invite_owner(school, school_owner_params, token)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error inviting school owner: #{e}"
        response
      end

      private

      def invite_owner(school, school_owner_params, token)
        organisation_id = school.id
        email_address = school_owner_params.fetch(:email_address)

        raise ArgumentError, "email address '#{email_address}' is invalid" unless EmailValidator.valid?(email_address)

        response = ProfileApiClient.invite_school_owner(token:, email_address:, organisation_id:)
        user_id = response.fetch(:id)

        User.from_userinfo(ids: user_id).first
      end
    end
  end
end
