# frozen_string_literal: true

module SchoolOwner
  class List
    class << self
      def call(school:, owner_ids: nil)
        response = OperationResponse.new
        owner_ids = school.roles.where(role: :owner)&.pluck(:user_id) if owner_ids.blank?
        response[:school_owners] = list_owners(owner_ids)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error listing school owners: #{e}"
        response
      end

      private

      def list_owners(ids)
        User.from_userinfo(ids:)
      end
    end
  end
end
