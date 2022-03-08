# frozen_string_literal: true

module Api
  class ProjectsController < ApiController
    require 'phrase_identifier'
    before_action :require_oauth_user, only: %i[update]
    before_action :load_project
    load_and_authorize_resource

    def show
      render :show, formats: [:json]
    end

    def update
      result = Project::Operation::Update.(project_params, @project)
      components = project_params[:components]
      components.each do |comp_params|
        component = Component.find(comp_params[:id])
        component.update(comp_params)
      end
      head :ok
    end

    private

    def load_project
      @project = Project.find_by!(identifier: params[:id])
    end

    def project_params
      params.require(:project)
            .permit(:name,
                    components: %i[id name extension content index])
    end
  end
end
