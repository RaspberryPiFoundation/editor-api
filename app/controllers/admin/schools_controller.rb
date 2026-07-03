# frozen_string_literal: true

module Admin
  class SchoolsController < Admin::ApplicationController
    helper_method :school_role_users_by_id

    def verify
      service = SchoolVerificationService.new(requested_resource)

      if service.verify
        flash[:notice] = t('administrate.controller.verify_school.success')
      else
        flash[:error] = t('administrate.controller.verify_school.error')
      end

      redirect_to admin_school_path(requested_resource)
    end

    def reopen
      service = SchoolVerificationService.new(requested_resource)

      if service.reopen
        flash[:notice] = t('administrate.controller.reopen_school.success')
      else
        flash[:error] = t('administrate.controller.reopen_school.error')
      end

      redirect_to admin_school_path(requested_resource)
    end

    def archive
      requested_resource.archive!

      redirect_to admin_school_path(requested_resource)
    end

    def default_sorting_attribute
      :created_at
    end

    def default_sorting_direction
      :desc
    end

    private

    def school_role_users_by_id
      @school_role_users_by_id ||= fetch_users_batch(school_role_user_ids)
    end

    def school_role_user_ids
      requested_resource.roles.where(role: SchoolRolesField::DISPLAYED_ROLES).filter_map(&:user_id).uniq
    end

    def fetch_users_batch(user_ids)
      User.from_userinfo(ids: user_ids).index_by(&:id)
    end
  end
end
