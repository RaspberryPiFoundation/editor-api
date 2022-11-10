# frozen_string_literal: true

module Api
  class ProjectsController < ApiController
    before_action :require_oauth_user, only: %i[update index destroy create]
    before_action :load_project, only: %i[show update destroy]
    before_action :load_projects, only: %i[index]
    load_and_authorize_resource
    skip_load_resource only: :create

    def index
      render :index, formats: [:json]
    end

    def show
      render :show, formats: [:json]
    end

    def create
      result = Project::Operation::Create.call(params: project_params, user_id: current_user)

      if result.success?
        @project = result[:project]
        render :show, formats: [:json]
      else
        render json: { error: result[:error] }, status: :internal_server_error
      end
    end

    def update
      result = Project::Operation::Update.call(params: project_params, project: @project)

      if result.success?
        render :show, formats: [:json]
      else
        render json: { error: result[:error] }, status: :bad_request
      end
    end

    def destroy
      @project.destroy
      head :ok
    end

    private

    def load_project
      @project = Project.find_by!(identifier: params[:id])
    end

    def load_projects
      @projects = Project.where(user_id: current_user)
    end

    def project_params
      params.permit(project: [
                               :name,
                               :project_type,
                               {
                                 image_list: [],
                                 components: %i[id name extension content index default]
                               }
                             ]).fetch(:project, {})
    end
  end
end
