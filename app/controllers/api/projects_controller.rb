# frozen_string_literal: true

module Api
  class ProjectsController < ApiController
    require 'phrase_identifier'

    before_action :require_oauth_user, only: %i[update]

    def show
      @project = Project.find_by!(identifier: params[:id])
      render :show, formats: [:json]
    end

    def update
      @project = Project.find_by!(identifier: params[:id])
      authorize! :update, @project

      components = project_params[:components]
      components.each do |comp_params|
        component = Component.find(comp_params[:id])
        component.update(comp_params)
      end
      head :ok
    end

    private

    def project_params
      params.require(:project)
            .permit(:identifier,
                    :type,
                    components: %i[id name extension content])
    end
  end
end
