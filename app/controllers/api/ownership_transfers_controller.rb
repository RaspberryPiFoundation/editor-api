# frozen_string_literal: true

module Api
  class OwnershipTransfersController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :school
    authorize_resource :ownership_transfer, class: false

    def show
      @ownership_transfer = most_recent_ownership_transfer

      if @ownership_transfer.blank? || cannot?(:read, @ownership_transfer)
        head :not_found
      elsif current_user_is_an_owner?
        render json: { status: @ownership_transfer.status, you_are: 'owner', nominee_name:, nominee_email: }, status: :ok
      else
        render json: { status: @ownership_transfer.status, you_are: 'nominee' }, status: :ok
      end
    end

    def create
      result = OwnershipTransfer::Create.call(school: @school, nominated_user_id:, requested_by_user_id: current_user.id)

      if result.success?
        head :created
      else
        render json: { error: result[:error] }, status: :unprocessable_content
      end
    end

    private

    def ownership_transfer_params
      params.expect(ownership_transfer: [:nominated_user_id])
    end

    def nominated_user_id
      ownership_transfer_params[:nominated_user_id]
    end

    def most_recent_ownership_transfer
      @school.ownership_transfers.order(created_at: :desc).first
    end

    def current_user_is_an_owner?
      current_user.school_owner?(@school)
    end

    def nominee_name
      User.from_userinfo(ids: @ownership_transfer.nominated_user_id).first&.name
    end

    def nominee_email
      @ownership_transfer.email_address
    end
  end
end
