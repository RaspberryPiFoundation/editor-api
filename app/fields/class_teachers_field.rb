# frozen_string_literal: true

require 'administrate/field/base'

class ClassTeachersField < Administrate::Field::Base
  def teachers
    @teachers ||= data.sort_by(&:created_at)
  end

  def user_display(teacher, users_by_id = {})
    user = users_by_id[teacher.user_id]
    user.present? ? user_dashboard.display_resource(user) : teacher.user_id
  end

  private

  def user_dashboard
    @user_dashboard ||= UserDashboard.new
  end
end
