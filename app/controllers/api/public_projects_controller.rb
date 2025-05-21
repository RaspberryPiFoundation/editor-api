# frozen_string_literal: true

module Api
  class PublicProjectsController < ApiController
    before_action :authorize_user

    def create
      result = PublicProject::Create.call(project_hash: project_params)

      if result.success?
        @project = result[:project]
        render 'api/projects/show', formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def project_params
      params.fetch(:project, {}).permit(:identifier, :locale, :project_type, :name)
    end
  end
end
