# frozen_string_literal: true

module Api
  class PublicProjectsController < ApiController
    before_action :authorize_user
    before_action :restrict_project_type, only: %i[create]
    before_action :load_project, only: %i[update]

    def create
      authorize! :create, :public_project
      result = PublicProject::Create.call(project_hash: create_params)

      if result.success?
        @project = result[:project]
        render 'api/projects/show', formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def update
      result = PublicProject::Update.call(project: @project, update_hash: update_params)

      if result.success?
        @project = result[:project]
        render 'api/projects/show', formats: [:json]
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def load_project
      @project = Project.find_by!(identifier: params[:id])
    end

    def create_params
      params.require(:project).permit(:identifier, :locale, :project_type, :name)
    end

    def update_params
      params.require(:project).permit(:identifier, :name)
    end

    def restrict_project_type
      project_type = create_params[:project_type]
      return if project_type == Project::Types::SCRATCH

      raise CanCan::AccessDenied.new("#{project_type} not yet supported", :create, :public_project)
    end
  end
end
