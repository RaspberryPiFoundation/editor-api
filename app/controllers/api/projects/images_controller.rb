# frozen_string_literal: true

module Api
  module Projects
    class ImagesController < ApiController
      before_action :authorize_user

      def create
        @project = Project.find_by!(identifier: params[:project_id])
        authorize! :update, @project
        @project.images.attach(params[:images])
        render '/api/projects/images', formats: [:json]
      end
    end
  end
end
