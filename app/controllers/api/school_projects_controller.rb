# frozen_string_literal: true

module Api
  class SchoolProjectsController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :project

    def show_status
      authorize! :show_status, school_project
      render :show_status, formats: [:json], status: :ok
    end

    def unsubmit
      authorize! :unsubmit, school_project
      result = SchoolProject::SetStatus.call(school_project:, status: :unsubmitted, user_id: current_user.id)
      if result.success?
        @school_project = result[:school_project]
        render :show_status, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def submit
      authorize! :submit, school_project
      result = SchoolProject::SetStatus.call(school_project:, status: :submitted, user_id: current_user.id)
      if result.success?
        @school_project = result[:school_project]
        render :show_status, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def return
      authorize! :return, school_project
      result = SchoolProject::SetStatus.call(school_project:, status: :returned, user_id: current_user.id)
      if result.success?
        @school_project = result[:school_project]
        render :show_status, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def complete
      authorize! :complete, school_project
      result = SchoolProject::SetStatus.call(school_project:, status: :complete, user_id: current_user.id)
      if result.success?
        @school_project = result[:school_project]
        render :show_status, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def show_finished
      authorize! :show_finished, school_project
      render :finished, formats: [:json], status: :ok
    end

    def set_finished
      authorize! :set_finished, school_project
      result = SchoolProject::SetFinished.call(school_project:, finished: params[:finished])

      if result.success?
        @school_project = result[:school_project]
        render :finished, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def project
      @project ||= Project.find_by!(identifier: params[:id])
    end

    def school_project
      @school_project ||= project.school_project
    end

    def school_project_params
      params.permit(:finished)
    end
  end
end
