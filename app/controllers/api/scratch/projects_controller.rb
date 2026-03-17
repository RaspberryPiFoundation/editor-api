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
        render json: { status: 'ok', 'content-name': 'new-project-id' }, status: :ok
      end

      def update
        scratch_content = params.permit!.slice(:meta, :targets, :monitors, :extensions)
        @project.scratch_component&.content = scratch_content.to_unsafe_h
        @project.save!
        render json: { status: 'ok' }, status: :ok
      end

      private

      def ensure_create_is_a_remix
        return if params[:is_remix] == '1'

        render json: { error: 'Only remixing existing projects is allowed' }, status: :forbidden
      end
    end
  end
end
