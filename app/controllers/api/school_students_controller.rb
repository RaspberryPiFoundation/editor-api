# frozen_string_literal: true

module Api
  class SchoolStudentsController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :school
    authorize_resource :school_student, class: false
    before_action :create_safeguarding_flags

    def index
      result = SchoolStudent::List.call(school: @school, token: current_user.token)

      if result.success?
        @school_students = result[:school_students]
        render :index, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def create
      result = SchoolStudent::Create.call(school: @school, school_student_params:, token: current_user.token)

      if result.success?
        head :no_content
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def create_batch
      result = SchoolStudent::CreateBatch.call(school: @school, uploaded_file: params[:file], token: current_user.token)

      if result.success?
        head :no_content
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def update
      result = SchoolStudent::Update.call(school: @school, school_student_params:, token: current_user.token)

      if result.success?
        head :no_content
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

    def create_safeguarding_flags
      create_teacher_safeguarding_flag
      create_owner_safeguarding_flag
    end

    def create_teacher_safeguarding_flag
      return unless current_user.school_teacher?(@school)

      ProfileApiClient.create_safeguarding_flag(
        token: current_user.token,
        flag: ProfileApiClient::SAFEGUARDING_FLAGS[:teacher]
      )
    end

    def create_owner_safeguarding_flag
      return unless current_user.school_owner?(@school)

      ProfileApiClient.create_safeguarding_flag(
        token: current_user.token,
        flag: ProfileApiClient::SAFEGUARDING_FLAGS[:owner]
      )
    end
  end
end
