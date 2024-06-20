# frozen_string_literal: true

module Admin
  class SchoolsController < Admin::ApplicationController
    def verify
      service = SchoolVerificationService.new(requested_resource)

      if service.verify
        flash[:notice] = t('administrate.controller.verify_school.success')
      else
        flash[:error] = t('administrate.controller.verify_school.error')
      end

      redirect_to admin_school_path(requested_resource)
    end

    def reject
      service = SchoolVerificationService.new(requested_resource)

      if service.reject
        flash[:notice] = t('administrate.controller.reject_school.success')
      else
        flash[:error] = t('administrate.controller.reject_school.error')
      end

      redirect_to admin_school_path(requested_resource)
    end

    def default_sorting_attribute
      :created_at
    end

    def default_sorting_direction
      :desc
    end
  end
end
