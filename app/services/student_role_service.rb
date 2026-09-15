# frozen_string_literal: true

class StudentRoleService
  class << self
    def ensure_student_role(user)
      return unless user.student_account_type?

      Role.student.find_or_create_by!(school_id: user.school_id, user_id: user.id)
    end
  end
end
