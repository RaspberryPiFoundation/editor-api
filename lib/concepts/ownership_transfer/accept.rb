# frozen_string_literal: true

class OwnershipTransfer
  class Accept
    class << self
      def call(ownership_transfer:)
        school = ownership_transfer.school

        OwnershipTransfer.transaction do
          demote_previous_owners(school, ownership_transfer.nominated_user_id)
          promote_nominee(school, ownership_transfer.nominated_user_id)
          ownership_transfer.update!(status: :completed)
        end
      end

      private

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
