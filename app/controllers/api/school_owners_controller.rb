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
  end
end
