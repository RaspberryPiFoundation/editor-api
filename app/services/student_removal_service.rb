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
        # Skip if student has projects
        projects = Project.where(user_id: user_id)
        result[:skipped] = true if projects.length.positive?

        unless result[:skipped]
          ActiveRecord::Base.transaction do
            # Remove from classes
            class_assignments = ClassStudent.where(student_id: user_id)
            class_assignments.destroy_all

            # Remove roles
            roles = Role.student.where(user_id: user_id)
            roles.destroy_all
          end

          # Remove from profile if requested
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
