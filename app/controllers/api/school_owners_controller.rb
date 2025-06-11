# frozen_string_literal: true

module Api
  class SchoolOwnersController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :school
    authorize_resource :school_owner, class: false

    def index
      result = SchoolOwner::List.call(school: @school)

      if result.success?
        @school_owners = result[:school_owners]
        render :index, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def create
      result = SchoolOwner::Invite.call(school: @school, school_owner_params:, token: current_user.token)

      if result.success?
        head :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def destroy
      result = SchoolOwner::Remove.call(school: @school, owner_id: params[:id], token: current_user.token)

      if result.success?
        head :no_content
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
