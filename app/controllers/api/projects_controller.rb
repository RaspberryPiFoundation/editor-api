# frozen_string_literal: true

module Api
  class ProjectsController < ApiController
    before_action :require_oauth_user, only: %i[update index]
    before_action :load_project, only: %i[show update]
    before_action :load_projects, only: %i[index]
    load_and_authorize_resource

    def index
      render :index, formats: [:json]
    end

    def show
      render :show, formats: [:json]
    end

    def update
      result = Project::Operation::Update.call(params: project_params, project: @project)

      if result.success?
        render :show, formats: [:json]
      else
        render json: { error: result[:error] }, status: :bad_request
      end
    end

    private

    def load_project
      @project = Project.find_by!(identifier: params[:id])
    end

    def load_projects
      @projects = Project.where(user_id: current_user)
    end

    def project_params
      params.require(:project)
            .permit(:name,
                    components: %i[id name extension content index])
    end
  end
end
