# frozen_string_literal: true

module Api
  class PublicProjectsController < ApiController
    before_action :authorize_user
    before_action :restrict_project_type, only: %i[create]
    before_action :load_project, only: %i[update destroy]
    before_action :restrict_to_public_projects, only: %i[update destroy]
    before_action :prevent_destruction_of_public_project_with_remixes, only: %i[destroy]

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
      authorize! :update, :public_project
      result = PublicProject::Update.call(project: @project, update_hash: update_params)

      if result.success?
        @project = result[:project]
        render 'api/projects/show', formats: [:json]
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def destroy
      authorize! :update, :public_project

      if @project.destroy
        head :ok
      else
        head :unprocessable_entity
      end
    end

    private

    def load_project
      loader = ProjectLoader.new(params[:id], [params[:locale]])
      @project = loader.load
      raise ActiveRecord::RecordNotFound if @project.blank?
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

    def restrict_to_public_projects
      return if @project.user_id.blank?

      raise CanCan::AccessDenied.new('Cannot update non-public project', :update, :public_project)
    end

    def prevent_destruction_of_public_project_with_remixes
      return if @project.remixes.none?

      raise CanCan::AccessDenied.new('Cannot destroy public project with remixes', :update, :public_project)
    end
  end
end
