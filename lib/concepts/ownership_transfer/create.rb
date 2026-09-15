# frozen_string_literal: true

class OwnershipTransfer
  class Create
    class << self
      def call(school:, nominated_user_id:, requested_by_user_id:)
        response = OperationResponse.new
        ownership_transfer = build_ownership_transfer(school:, nominated_user_id:, requested_by_user_id:)

        if ownership_transfer.save
          response[:ownership_transfer] = ownership_transfer
        else
          response[:error] = ownership_transfer.errors
        end

        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error creating ownership transfer: #{e}"
        response
      end

      private

      def build_ownership_transfer(school:, nominated_user_id:, requested_by_user_id:)
        email_address = nominee_email(school:, nominated_user_id:)
        OwnershipTransfer.new(school:, nominated_user_id:, requested_by_user_id:, email_address:)
      end

      def nominee_email(school:, nominated_user_id:)
        return unless school.roles.exists?(user_id: nominated_user_id, role: %i[owner teacher])

        User.from_userinfo(ids: nominated_user_id).first&.email
      end
    end
  end
end
