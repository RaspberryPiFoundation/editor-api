module Admin
  class ProjectsController < Admin::ApplicationController
    before_action :set_host_for_local_storage

    def scoped_resource
      resource_class.internal_projects
    end

    def destroy_image
      image = requested_resource.images.find(params[:image_id])
      image.purge
      redirect_back(fallback_location: requested_resource)
    end

    private
     def set_host_for_local_storage
        ActiveStorage::Current.host = request.base_url if Rails.application.config.active_storage.service == :local
    end
  end
end
