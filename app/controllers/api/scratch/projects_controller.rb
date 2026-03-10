# frozen_string_literal: true

module Api
  module Scratch
    class ProjectsController < ScratchController
      skip_before_action :authorize_user, only: [:show]
      skip_before_action :check_scratch_feature, only: [:show]
      before_action :load_project, only: %i[show update]

      def show
        render json: @project.scratch_component&.content
      end

      def update
        @project.scratch_component&.content = params
        @project.save
        render json: { status: 'ok' }, status: :ok
      end
    end
  end
end
