# frozen_string_literal: true

module Api
  class SchoolProjectsController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :project

    def set_status
      authorize! :set_status, @school_project
      response = SchoolProject::SetStatus.call(school_project: @school_project, status: params[:status])
      if response.success?
        @school_project = response[:school_project]
        render :show_status, formats: [:json], status: :ok
      else
        render json: { error: response[:error] }, status: :unprocessable_entity
      end
    end

    def show_finished
      authorize! :show_finished, @school_project
      render :finished, formats: [:json], status: :ok
    end

    def set_finished
      authorize! :set_finished, @school_project
      result = SchoolProject::SetFinished.call(school_project: @school_project, finished: params[:finished])

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
      params.permit(:finished, :status)
    end
  end
end
