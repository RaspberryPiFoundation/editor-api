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

          # Keep local DB changes uncommitted until Profile confirms deletion.
          delete_from_profile(user_id) if remove_from_profile?
        end
      rescue StandardError => e
        result[:error] = "#{e.class}: #{e.message}"
      end
      results << result
    end
    results
  end

  private

  def delete_from_profile(user_id)
    ensure_safeguarding_flag
    ProfileApiClient.delete_school_student(token: @token, school_id: @school.id, student_id: user_id)
  end

  def ensure_safeguarding_flag
    return if @safeguarding_flag_created

    SafeguardingFlagService.create_for_token(token: @token, school: @school)
    @safeguarding_flag_created = true
  end

  def remove_from_profile?
    @remove_from_profile && @token.present?
  end
end
