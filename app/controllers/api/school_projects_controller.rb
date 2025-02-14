# frozen_string_literal: true

module Api
  class SchoolProjectsController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :project

    def show_finished
      @school_project = Project.find_by(identifier: params[:id]).school_project
      authorize! :show_finished, @school_project
      render :finished, formats: [:json], status: :ok
    end

    def set_finished
      project = Project.find_by(identifier: params[:id])
      @school_project = project.school_project
      authorize! :set_finished, @school_project
      result = SchoolProject::SetFinished.call(school_project: @school_project, finished: params[:finished])

      if result.success?
        @school_project = result[:school_project]
        render :finished, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end
  end
end
