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
        filename_with_extension = "#{params[:id]}.#{params[:format]}"

        asset = ScratchAsset.new(filename: filename_with_extension)
        asset.file.attach(
          io: StringIO.new(params[:content].to_s),
          filename: filename_with_extension
        )

        asset.save!

        render json: { status: 'ok', 'content-name': params[:id] }, status: :created
      end
    end
  end
end
