# frozen_string_literal: true

require 'administrate/field/base'

class SchoolRolesField < Administrate::Field::Base
  DISPLAYED_ROLES = %w[owner teacher].freeze

  def roles
    @roles ||= data.where(role: DISPLAYED_ROLES).sort_by(&:created_at)
  end

  def user_display(role, users_by_id = {})
    user = users_by_id[role.user_id]
    user.present? ? user_dashboard.display_resource(user) : role.user_id
  end

  private

  def user_dashboard
    @user_dashboard ||= UserDashboard.new
  end
end
