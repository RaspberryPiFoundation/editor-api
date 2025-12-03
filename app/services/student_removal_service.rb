# frozen_string_literal: true

class StudentRemovalService
  def initialize(students:, school:, remove_from_profile: false, token: nil)
    @students = students
    @school = school
    @remove_from_profile = remove_from_profile
    @token = token
  end

  # Returns an array of hashes, one per student, with details of what was removed
  def remove_students
    results = []

    @students.each do |user_id|
      # Ensure that the student has a role in this school and skip if not.
      student_roles = Role.student.where(user_id:, school_id: @school.id)
      if student_roles.empty?
        results << { user_id:, skipped: true, reason: 'no_role_in_school' }
        next
      end

      result = { user_id: }
      begin
        ActiveRecord::Base.transaction do
          # Delete all projects for this user
          projects = Project.where(user_id: user_id)
          projects.destroy_all

          # Remove from classes
          class_assignments = ClassStudent.joins(:school_class).where(student_id: user_id, school_class: { school_id: @school.id })
          class_assignments.destroy_all

          # Remove roles
          student_roles.destroy_all

          # Remove from profile if requested - inside transaction so it can be rolled back
          # If this call fails, the entire transaction will be rolled back
          ProfileApiClient.delete_school_student(token: @token, school_id: @school.id, student_id: user_id) if @remove_from_profile && @token.present?
        end
      rescue StandardError => e
        result[:error] = "#{e.class}: #{e.message}"
      end
      results << result
    end
    results
  end
end
