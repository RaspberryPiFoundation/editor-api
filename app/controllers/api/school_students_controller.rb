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
      result = SchoolStudent::Create.call(
        school: @school, school_student_params:, token: current_user.token
      )

      if result.success?
        head :no_content
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def create_batch
      result = SchoolStudent::CreateBatch.call(
        school: @school, school_students_params:, token: current_user.token, user_id: current_user.id
      )

      if result.success?
        @job_id = result[:job_id]
        render :create_batch, formats: [:json], status: :accepted
      else
        render json: { error: result[:error], error_type: result[:error_type] }, status: :unprocessable_entity
      end
    end

    def update
      result = SchoolStudent::Update.call(
        school: @school, student_id: params[:id], school_student_params:, token: current_user.token
      )

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

    def school_students_params
      school_students = params.require(:school_students)

      school_students.map do |student|
        next if student.blank?

        student.permit(:username, :password, :name).to_h.with_indifferent_access
      end
    end

    def create_safeguarding_flags
      create_teacher_safeguarding_flag
      create_owner_safeguarding_flag
    end

    def create_teacher_safeguarding_flag
      return unless current_user.school_teacher?(@school)

      ProfileApiClient.create_safeguarding_flag(
        token: current_user.token,
        flag: ProfileApiClient::SAFEGUARDING_FLAGS[:teacher],
        email: current_user.email
      )
    end

    def create_owner_safeguarding_flag
      return unless current_user.school_owner?(@school)

      ProfileApiClient.create_safeguarding_flag(
        token: current_user.token,
        flag: ProfileApiClient::SAFEGUARDING_FLAGS[:owner],
        email: current_user.email
      )
    end
  end
end
