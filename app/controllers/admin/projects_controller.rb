# frozen_string_literal: true

module Admin
  class ProjectsController < Admin::ApplicationController
    before_action :set_host_for_local_storage

    def scoped_resource
      action_name == 'index' ? resource_class.internal_projects : resource_class.all
    end

    def destroy_image
      image = requested_resource.images.find(params[:image_id])
      image.purge
      redirect_back(fallback_location: requested_resource)
    end

    private

    def set_host_for_local_storage
      return unless Rails.application.config.active_storage.service == :local

      ActiveStorage::Current.url_options = { host: request.base_url }
    end
  end
end
