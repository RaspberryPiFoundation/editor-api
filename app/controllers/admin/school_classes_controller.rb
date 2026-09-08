# frozen_string_literal: true

module Admin
  class SchoolClassesController < Admin::ApplicationController
    helper_method :class_teacher_users_by_id

    private

    def class_teacher_users_by_id
      @class_teacher_users_by_id ||= User.from_userinfo(ids: requested_resource.teachers.map(&:user_id).uniq).index_by(&:id)
    end
  end
end
