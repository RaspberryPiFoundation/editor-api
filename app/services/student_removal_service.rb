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
      result = { user_id: }
      begin
        projects_scope = Project.where(user_id:, school_id: @school.id)
        result[:skipped] = true if projects_scope.exists?

        unless result[:skipped]
          ActiveRecord::Base.transaction do
            class_assignments = ClassStudent.where(student_id: user_id)
            class_assignments.destroy_all

            roles = Role.student.where(user_id: user_id)
            roles.destroy_all
          end

          if @remove_from_profile && @token.present?
            ProfileApiClient.delete_school_student(
              token: @token,
              school_id: @school.id,
              student_id: user_id
            )
          end
        end
      rescue StandardError => e
        result[:error] = "#{e.class}: #{e.message}"
      end
      results << result
    end
    results
  end
end
