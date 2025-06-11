# frozen_string_literal: true

module Api
  module Projects
    class RemixesController < ApiController
      before_action :authorize_user
      load_and_authorize_resource :school, only: :index
      before_action :load_and_authorize_remix, only: %i[show]

      def index
        projects = Project.where(remixed_from_id: project.id).accessible_by(current_ability)
        @projects_with_users = projects.includes(:school_project).with_users(@current_user)
        render index: @projects_with_users, formats: [:json]
      end

      def show
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

      def load_and_authorize_remix
        @project = Project.find_by!(remixed_from_id: project.id, user_id: current_user&.id)
        authorize! :show, @project
      end

      def remix_params
        params.require(:project)
              .permit(:name,
                      :identifier,
                      :project_type,
                      :locale,
                      :user_id,
                      :videos,
                      :audio,
                      :instructions,
                      image_list: %i[filename url content],
                      components: %i[id name extension content index])
      end
    end
  end
end
