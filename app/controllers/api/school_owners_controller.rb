# frozen_string_literal: true

module Api
  class SchoolOwnersController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :school
    authorize_resource :school_owner, class: false

    def create
      result = SchoolOwner::Invite.call(school: @school, school_owner_params:, token: current_user.token)

      if result.success?
        @school_owner = result[:school_owner]
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def school_owner_params
      params.require(:school_owner).permit(:email_address)
    end
  end
end
