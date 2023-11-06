# frozen_string_literal: true

module Api
  module Projects
    class RemixesController < ApiController
      before_action :authorize_user

      def create
        result = Project::CreateRemix.call(params: remix_params,
                                           user_id: current_user,
                                           original_project: project,
                                           remix_origin: request.origin
                                          )

        if result.success?
          @project = result[:project]
          render '/api/projects/show', formats: [:json]
        else
          render json: { error: result[:error] }, status: :bad_request
        end
      end

      private

      def project
        @project ||= Project.find_by!(identifier: params[:project_id])
      end

      def remix_params
        params.require(:project)
              .permit(:name,
                      :identifier,
                      :locale,
                      components: %i[id name extension content index])
      end
    end
  end
end
