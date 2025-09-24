# frozen_string_literal: true

module SchoolMember
  class List
    # TODO: This should be using the User model for consistency
    SchoolMember = Struct.new(:id, :name, :username, :email, :type, :sso) do
      def initialize(id, name, username, email, type, sso = nil)
        super
      end
    end

    class << self
      # rubocop:disable Metrics/CyclomaticComplexity
      def call(school:, token:)
        response = OperationResponse.new
        response[:school_members] = []

        students = teachers = owners = []

        begin
          # Only call students API if there are actually students in the school
          student_roles = Role.student.where(school:)
          students_response = student_roles.any? ? SchoolStudent::List.call(school:, token:).fetch(:school_students, []) : []
          
          teachers_response = SchoolTeacher::List.call(school:).fetch(:school_teachers, [])
          owners_response = SchoolOwner::List.call(school:).fetch(:school_owners, [])

          students = students_response.map do |student|
            sso_student = student.email.present? && student.username.blank?
            SchoolMember.new(student.id, student.name, student.username, student.email, :student, sso_student)
          end
          owners = owners_response.map do |owner|
            SchoolMember.new(owner.id, owner.name, nil, owner.email, :owner)
          end
          owner_ids = owners.map(&:id)
          teachers = teachers_response.reject { |teacher| owner_ids.include?(teacher.id) }.map do |teacher|
            SchoolMember.new(teacher.id, teacher.name, nil, teacher.email, :teacher)
          end
        rescue StandardError => e
          Sentry.capture_exception(e)
          response[:error] = "Error listing school members: #{e}"
          response
        end

        response[:school_members] = (owners + teachers + students).sort_by(&:name)
        response
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
  end
end
