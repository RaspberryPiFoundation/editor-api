# frozen_string_literal: true

module Api
  class ProjectErrorsController < ApiController
    def create
      project_error = ProjectError.new(project_error_params)
      project_error.save!

      render json: { data: project_error }, status: :created
    end

    rescue_from ActiveRecord::RecordInvalid, with: :generic_error_response

    def raw_params
      params.permit(
        :project_id,
        :error,
        :user_id
      )
    end

    def project_error_params
      py_params = raw_params

      project_id = py_params.delete(:project_id)

      if project_id
        project = Project.find_by(identifier: project_id)
        py_params[:project_id] = project&.id || nil
      end

      py_params
    end

    def generic_error_response(exception)
      render json: { data: [], error: exception.message }, status: :bad_request
    end
  end
end
