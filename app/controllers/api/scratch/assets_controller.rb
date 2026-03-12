# frozen_string_literal: true

module Api
  module Scratch
    class AssetsController < ScratchController
      skip_before_action :authorize_user, only: [:show]
      skip_before_action :check_scratch_feature, only: [:show]

      def show
        render :show, formats: [:svg]
      end

      def create
        render json: { status: 'ok', 'content-name': params[:id] }, status: :created
      end
    end
  end
end
