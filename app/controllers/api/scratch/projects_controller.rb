# frozen_string_literal: true

module Api
  module Scratch
    class ProjectsController < ScratchController
      skip_before_action :authorize_user, only: [:show]
      skip_before_action :check_scratch_feature, only: [:show]
      before_action :load_project, only: %i[show update]

      before_action :ensure_create_is_a_remix, only: %i[create]

      def show
        render json: @project.scratch_component.content
      end

      def create
        original_project = load_original_project(source_project_identifier)
        return render json: { error: I18n.t('errors.admin.unauthorized') }, status: :unauthorized unless current_ability.can?(:show, original_project)

        remix_params = create_params
        return render json: { error: I18n.t('errors.project.remixing.invalid_params') }, status: :bad_request if remix_params.dig(:scratch_component, :content).blank?

        remix_origin = request.origin || request.referer

        result = Project::CreateRemix.call(
          params: remix_params,
          user_id: current_user.id,
          original_project:,
          remix_origin:
        )

        if result.success?
          render json: { status: 'ok', 'content-name': result[:project].identifier }, status: :ok
        else
          render json: { error: result[:error] }, status: :bad_request
        end
      end

      def update
        @project.scratch_component&.content = scratch_content_params
        @project.save!
        render json: { status: 'ok' }, status: :ok
      end

      private

      def ensure_create_is_a_remix
        return if params[:is_remix] == '1' && params[:original_id].present?

        render json: { error: I18n.t('errors.project.remixing.only_existing_allowed') }, status: :forbidden
      end

      def source_project_identifier
        params[:original_id]
      end

      def create_params
        {
          identifier: source_project_identifier,
          scratch_component: { content: scratch_content_params }
        }
      end

      def load_original_project(identifier)
        project_loader = ProjectLoader.new(identifier, [params[:locale]])
        original_project = project_loader.load

        raise ActiveRecord::RecordNotFound, I18n.t('errors.project.not_found') unless original_project
        raise ActiveRecord::RecordNotFound, I18n.t('errors.project.not_found') unless original_project.scratch_project?

        original_project
      end

      def scratch_content_params
        params.slice(:meta, :targets, :monitors, :extensions).to_unsafe_h
      end
    end
  end
end
