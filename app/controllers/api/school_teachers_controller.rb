# frozen_string_literal: true

module Api
  class SchoolTeachersController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :school
    authorize_resource :school_teacher, class: false

    def index
      result = SchoolTeacher::List.call(school: @school)

      if result.success?
        @school_teachers = result[:school_teachers]
        render :index, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def create
      result = SchoolTeacher::Invite.call(school: @school, school_teacher_params:, token: current_user.token)

      if result.success?
        head :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def school_teacher_params
      params.require(:school_teacher).permit(:email_address)
    end
  end
end
