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

    # Wrapped in a transaction so the row lock below is held across the
    # read-and-update, preventing a concurrent accept/decline/cancel on the
    # same transfer from also finding it pending. Authorizing against the loaded
    # transfer (rather than checking cannot? by hand) means an unauthorized
    # attempt raises and is rescued below into the same 404 a nonexistent
    # transfer gets, instead of leaking that a pending transfer exists.
    #
    # head/render stay outside the transaction block: the transfer's
    # after_update_commit callback (sends the cancellation email) runs inside
    # it, and we want a failure there to be the only thing we respond with.
    def resolve!(status)
      transfer = OwnershipTransfer.transaction do
        loaded = pending_ownership_transfer
        next if loaded.blank?

        authorize!(action_name.to_sym, loaded)
        loaded.update(status:)
        loaded
      end

      if transfer.nil?
        head :not_found
      elsif transfer.errors.empty?
        head :ok
      else
        render json: { error: transfer.errors }, status: :unprocessable_content
      end
    rescue CanCan::AccessDenied
      head :not_found
    end

    def pending_ownership_transfer
      @school.ownership_transfers.lock.pending.first
    end
  end
end
