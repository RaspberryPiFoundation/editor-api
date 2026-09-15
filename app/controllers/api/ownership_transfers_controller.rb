# frozen_string_literal: true

module Api
  class OwnershipTransfersController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :school
    authorize_resource :ownership_transfer, class: false

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
  end
end
