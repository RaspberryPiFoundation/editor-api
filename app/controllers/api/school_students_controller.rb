# frozen_string_literal: true

module Api
  class SchoolStudentsController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :school
    authorize_resource :school_student, class: false

    def create
      result = SchoolStudent::Create.call(school: @school, school_student_params:, token: current_user.token)

      if result.success?
        @school_student = result[:school_student]
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def destroy
      result = SchoolStudent::Delete.call(school: @school, student_id: params[:id], token: current_user.token)

      if result.success?
        head :no_content
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def school_student_params
      params.require(:school_student).permit(:username, :password, :name)
    end
  end
end
