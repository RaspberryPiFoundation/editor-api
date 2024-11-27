# frozen_string_literal: true

module Admin
  class SchoolsController < Admin::ApplicationController
    def verify
      service = SchoolVerificationService.new(requested_resource)

      begin
        service.verify(token: current_user.token)
        flash[:notice] = t('administrate.controller.verify_school.success')
      rescue StandardError => e
        flash[:error] = "#{t('administrate.controller.verify_school.error')}: #{e.message}"
      end

      redirect_to admin_school_path(requested_resource)
    end

    def reject
      service = SchoolVerificationService.new(requested_resource)

      begin
        service.reject
        flash[:notice] = t('administrate.controller.reject_school.success')
      rescue StandardError => e
        flash[:error] = "#{t('administrate.controller.reject_school.error')}: #{e.message}"
      end

      redirect_to admin_school_path(requested_resource)
    end

    def blitz_reject
      service = SchoolVerificationService.new(requested_resource)

      begin
        service.blitz_reject
        flash[:notice] = t('administrate.controller.reject_school.success')
      rescue StandardError => e
        flash[:error] = "#{t('administrate.controller.reject_school.error')}: #{e.message}"
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
