# frozen_string_literal: true

module Api
  class OwnershipTransferResolutionsController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :school
    before_action -> { authorize!(:read, :ownership_transfer) }

    def accept
      resolve!(:completed)
    end

    def decline
      resolve!(:rejected)
    end

    def cancel
      resolve!(:cancelled)
    end

    private

    # The lock is held until update finishes, so two requests can't both act
    # on the same pending transfer at once.
    #
    # Not found and not authorized both raise into the same head :not_found
    # below, so the response can't be used to tell whether a transfer exists
    # that the user just isn't allowed to touch.
    #
    # head/render happen after the transaction, not inside it, so a failure
    # sending the cancellation email (its after_commit callback) is the only
    # thing we respond with.
    def resolve!(status)
      transfer = OwnershipTransfer.transaction do
        loaded = pending_ownership_transfer
        authorize!(action_name.to_sym, loaded)
        loaded.update(status:)
        loaded
      end

      if transfer.errors.empty?
        head :ok
      else
        render json: { error: transfer.errors }, status: :unprocessable_content
      end
    rescue CanCan::AccessDenied, ActiveRecord::RecordNotFound
      head :not_found
    end

    def pending_ownership_transfer
      @school.ownership_transfers.lock.pending.first!
    end
  end
end
