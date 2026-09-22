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

    private

    # Wrapped in a transaction so the row lock below is held across the
    # read-and-update, preventing a concurrent accept/decline on the same
    # transfer from also finding it pending. Authorizing against the loaded
    # transfer (rather than checking cannot? by hand) means an unauthorized
    # attempt raises and is rescued below into the same 404 a nonexistent
    # transfer gets, instead of leaking that a pending transfer exists.
    def resolve!(status)
      OwnershipTransfer.transaction do
        transfer = pending_ownership_transfer
        return head(:not_found) if transfer.blank?

        authorize!(action_name.to_sym, transfer)

        if transfer.update(status:)
          head :ok
        else
          render json: { error: transfer.errors }, status: :unprocessable_content
        end
      end
    rescue CanCan::AccessDenied
      head :not_found
    end

    def pending_ownership_transfer
      @school.ownership_transfers.lock.pending.first
    end
  end
end
