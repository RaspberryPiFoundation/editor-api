# frozen_string_literal: true

module Api
  module Scratch
    class ProjectsController < ScratchController
      skip_before_action :authorize_user, only: [:show]
      skip_before_action :check_scratch_feature, only: [:show]

      def show
        render :show, formats: [:json]
      end

      def update
        render json: { status: 'ok' }, status: :ok
      end
    end
  end
end
