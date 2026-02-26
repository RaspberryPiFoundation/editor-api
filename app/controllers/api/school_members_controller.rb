# frozen_string_literal: true

module Api
  class SchoolMembersController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :school
    authorize_resource :school_member, class: false

    before_action :create_safeguarding_flags

    def index
      result = SchoolMember::List.call(school: @school, token: current_user.token)

      if result.success?
        @school_members = result[:school_members]
        render :index, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def create_safeguarding_flags
      create_teacher_safeguarding_flag
      create_owner_safeguarding_flag
    end

    def create_teacher_safeguarding_flag
      return unless current_user.school_teacher?(@school)

      ProfileApiClient.create_safeguarding_flag(
        token: current_user.token,
        flag: ProfileApiClient::SAFEGUARDING_FLAGS[:teacher],
        email: current_user.email,
        school_id: @school.id
      )
    end

    def create_owner_safeguarding_flag
      return unless current_user.school_owner?(@school)

      ProfileApiClient.create_safeguarding_flag(
        token: current_user.token,
        flag: ProfileApiClient::SAFEGUARDING_FLAGS[:owner],
        email: current_user.email,
        school_id: @school.id
      )
    end
  end
end
