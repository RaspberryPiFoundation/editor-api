# frozen_string_literal: true

class OwnershipTransfer
  class Accept
    class << self
      def call(school:)
        response = OperationResponse.new

        OwnershipTransfer.transaction do
          ownership_transfer = pending_ownership_transfer(school)
          response[:ownership_transfer] = ownership_transfer

          demote_previous_owners(school, ownership_transfer.nominated_user_id)
          promote_nominee(school, ownership_transfer.nominated_user_id)
          ownership_transfer.update!(status: :completed)
        end

        response
      rescue ActiveRecord::RecordNotFound
        raise
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = response[:ownership_transfer]&.errors.presence || 'Error accepting ownership transfer'
        response
      end

      private

      def pending_ownership_transfer(school)
        school.ownership_transfers.lock.pending.first!
      end

      def demote_previous_owners(school, nominated_user_id)
        school.roles.owner.where.not(user_id: nominated_user_id).find_each(&:archive!)
      end

      def promote_nominee(school, nominated_user_id)
        role = Role.unscoped.owner.find_or_initialize_by(school:, user_id: nominated_user_id)
        role.archived_at = nil
        role.save!
      end
    end
  end
end
