# frozen_string_literal: true

module Admin
  class SchoolsController < Admin::ApplicationController
    def authorized_action?(resource, action)
      case action
      when :verify_school
        resource&.rejected_at.present? || resource&.verified_at.nil?
      when :reject_school
        resource&.verified_at.present? || resource&.rejected_at.nil?
      else
        super
      end
    end

    def verify_school
      school_id = params[:school_id]
      service = SchoolVerificationService.new(school_id)

      if service.verify
        flash[:notice] = t('administrate.controller.verify_school.success')
      else
        flash[:error] = t('administrate.controller.verify_school.error')
      end

      redirect_to admin_school_path(id: school_id)
    end

    def reject_school
      school_id = params[:school_id]
      service = SchoolVerificationService.new(school_id)

      if service.reject
        flash[:notice] = t('administrate.controller.reject_school.success')
      else
        flash[:error] = t('administrate.controller.reject_school.error')
      end

      redirect_to admin_school_path(id: school_id)
    end
  end
end
