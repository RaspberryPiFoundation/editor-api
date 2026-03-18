# frozen_string_literal: true

module Api
  module Scratch
    class AssetsController < ScratchController
      skip_before_action :authorize_user, only: [:show]
      skip_before_action :check_scratch_feature, only: [:show]

      def show
        filename_with_extension = "#{params[:id]}.#{params[:format]}"
        redirect_to rails_storage_redirect_url(ScratchAsset.find_by!(filename: filename_with_extension).file)
      end

      def create
        begin
          filename_with_extension = "#{params[:id]}.#{params[:format]}"
          ScratchAsset.find_or_create_by!(filename: filename_with_extension) do |a|
            a.file.attach(io: request.body, filename: filename_with_extension)
          end
        rescue ActiveRecord::RecordNotUnique => e
          logger.error(e)
        end

        render json: { status: 'ok', 'content-name': params[:id] }, status: :created
      end
    end
  end
end
