# frozen_string_literal: true

module Admin
  class ProjectsController < Admin::ApplicationController
    include ActiveStorage::SetCurrent

    def scoped_resource
      resource_class.internal_projects
    end

    def destroy_image
      image = requested_resource.images.find(params[:image_id])
      image.purge
      redirect_back(fallback_location: requested_resource)
    end
  end
end
