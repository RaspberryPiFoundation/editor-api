# frozen_string_literal: true

module Api
  module Scratch
    class ProjectsController < ScratchController
      include RemixSelection

      skip_before_action :authorize_user, only: [:show]
      skip_before_action :check_scratch_feature, only: [:show]
      before_action :load_project, only: %i[show update]

      before_action :ensure_create_is_a_remix, only: %i[create]

      def show
        render json: scratch_project_content(@project.scratch_component.content.to_h)
      end

      def create
        original_project = load_original_project(source_project_identifier)
        return render json: { error: I18n.t('errors.admin.unauthorized') }, status: :unauthorized unless current_ability.can?(:show, original_project)

        remix_params = create_params
        return render json: { error: I18n.t('errors.project.remixing.invalid_params') }, status: :bad_request if remix_params.dig(:scratch_component, :content).blank?

        existing_remix = remix_for_user(original_project, current_user)
        if existing_remix
          scratch_component = existing_remix.scratch_component || existing_remix.build_scratch_component
          scratch_component.content = scratch_content_params
          existing_remix.save!
          reassign_uploaded_scratch_assets(original_project:, remix_project: existing_remix)

          return render json: { status: 'ok', 'content-name': existing_remix.identifier }, status: :ok
        end

        remix_origin = request.origin || request.referer

        result = Project::CreateRemix.call(
          params: remix_params,
          user_id: current_user.id,
          original_project:,
          remix_origin:
        )

        if result.success?
          reassign_uploaded_scratch_assets(original_project:, remix_project: result[:project])
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
        Project.find_by!(identifier:, project_type: Project::Types::CODE_EDITOR_SCRATCH)
      end

      def scratch_content_params
        params.slice(:meta, :targets, :monitors, :extensions).to_unsafe_h
      end

      def scratch_project_content(content)
        targets = content['targets']
        return content unless targets.is_a?(Array)

        stage_targets, other_targets = targets.partition do |target|
          target.is_a?(Hash) && (target['isStage'] || target[:isStage])
        end
        return content if stage_targets.empty?

        content.merge('targets' => stage_targets + other_targets)
      end

      def reassign_uploaded_scratch_assets(original_project:, remix_project:)
        uploaded_user_id = current_user.id
        return if skip_scratch_asset_reassignment?(
          original_project:,
          remix_project:,
          uploaded_user_id:
        )

        ScratchAsset.where(project: original_project, uploaded_user_id:).find_each do |source_asset|
          reassign_uploaded_scratch_asset(
            source_asset:,
            remix_project:,
            uploaded_user_id:
          )
        end
      rescue StandardError => e
        Sentry.capture_exception(e)
      end

      def skip_scratch_asset_reassignment?(original_project:, remix_project:, uploaded_user_id:)
        original_project.blank? ||
          remix_project.blank? ||
          uploaded_user_id.blank? ||
          original_project.id == remix_project.id
      end

      def reassign_uploaded_scratch_asset(source_asset:, remix_project:, uploaded_user_id:)
        if ScratchAsset.exists?(project: remix_project, uploaded_user_id:, filename: source_asset.filename)
          source_asset.destroy!
        else
          source_asset.update!(project: remix_project)
        end
      rescue ActiveRecord::RecordNotUnique
        source_asset.destroy!
      end
    end
  end
end
