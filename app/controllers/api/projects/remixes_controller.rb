# frozen_string_literal: true

module Api
  module Projects
    class RemixesController < ApiController
      before_action :authorize_user
      load_and_authorize_resource :school, only: :index

      def index
        projects = Project.where(remixed_from_id: project.id).accessible_by(current_ability)
        @projects_with_users = projects.with_users(@current_user)
        render index: @projects_with_users, formats: [:json]
      end

      def show
        @project = Project.find_by!(remixed_from_id: project.id, user_id: current_user&.id)

        render '/api/projects/show', formats: [:json]
      end

      def create
        # Ensure we have a fallback value to prevent bad requests
        remix_origin = request.origin || request.referer
        result = Project::CreateRemix.call(params: remix_params,
                                           user_id: current_user&.id,
                                           original_project: project,
                                           remix_origin:)

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
                      :project_type,
                      :locale,
                      :user_id,
                      images: [],
                      components: %i[id name extension content index])
      end
    end
  end
end
