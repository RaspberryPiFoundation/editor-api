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
      def call(school:, token:)
        response = OperationResponse.new
        response[:school_members] = []

        begin
          students = fetch_students(school:, token:)
          teachers = fetch_teachers(school:)
          owners = fetch_owners(school:)

          # Filter out teachers who are also owners
          owner_ids = owners.map(&:id)
          filtered_teachers = teachers.reject { |teacher| owner_ids.include?(teacher.id) }

          response[:school_members] = (owners + filtered_teachers + students).sort_by(&:name)
        rescue StandardError => e
          Sentry.capture_exception(e)
          response[:error] = "Error listing school members: #{e}"
          return response
        end

        response
      end

      private

      def fetch_students(school:, token:)
        student_roles = Role.student.where(school:)
        students_response = student_roles.any? ? SchoolStudent::List.call(school:, token:).fetch(:school_students, []) : []

        students_response.map do |student|
          sso_student = student.email.present? && student.username.blank?
          SchoolMember.new(student.id, student.name, student.username, student.email, :student, sso_student)
        end
      end

      def fetch_teachers(school:)
        teachers_response = SchoolTeacher::List.call(school:).fetch(:school_teachers, [])

        teachers_response.map do |teacher|
          SchoolMember.new(teacher.id, teacher.name, nil, teacher.email, :teacher)
        end
      end

      def fetch_owners(school:)
        owners_response = SchoolOwner::List.call(school:).fetch(:school_owners, [])

        owners_response.map do |owner|
          SchoolMember.new(owner.id, owner.name, nil, owner.email, :owner)
        end
      end
    end
  end
end
