# frozen_string_literal: true

module Api
  class SchoolProjectsController < ApiController
    before_action :authorize_user, only: %i[show set_finished]
    load_and_authorize_resource :school_project

    def show
      render :show, formats: [:json], status: :ok
    end

    def set_finished
      project = Project.find_by(identifier: params[:id])
      result = SchoolProject::SetFinished.call(school_project: project.school_project, finished: params[:finished])

      if result.success?
        head :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    # private

    # def school_project_params
    #   params.require(:school_project).permit(
    #     :school_id,
    #     :project_id,
    #     :finished
    #   )
    # end
  end
end
