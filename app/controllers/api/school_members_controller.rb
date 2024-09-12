# frozen_string_literal: true

module Api
  class SchoolMembersController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :school

    def index
      result = SchoolMember::List.call(school: @school, token: current_user.token)

      if result.success?
        @school_members = result[:school_members]
        render :index, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end
  end
end
