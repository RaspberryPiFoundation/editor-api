# frozen_string_literal: true

module Api
  module Projects
    class ImagesController < ApiController
      before_action :require_oauth_user

      def create
        @project = Project.find_by!(identifier: params[:project_id])
        @project.images.attach(params[:images])
        render '/api/projects/images', formats: [:json]
      end
    end
  end
end
