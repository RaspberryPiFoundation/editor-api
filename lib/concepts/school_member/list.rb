# frozen_string_literal: true

module SchoolMember
  class List
    # TODO: This should be using the User model for consistency
    SchoolMember = Struct.new(:id, :name, :username, :email, :type, :sso_providers) do
      def initialize(id, name, username, email, type, sso_providers = [])
        super
      end
    end

    class << self
      def call(school:, token:)
        response = OperationResponse.new
        response[:school_members] = []

        begin
          students_response = fetch_students(school:, token:)
          if students_response.failure?
            response[:error] = students_response[:error]
            return response
          end

          students = build_student_members(students_response.fetch(:school_students, []))
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

        student_roles.any? ? SchoolStudent::List.call(school:, token:) : OperationResponse[school_students: []]
      end

      def build_student_members(students)
        students.map do |student|
          SchoolMember.new(student.id, student.name, student.username, student.email, :student, student.sso_providers)
        end
      end

      def fetch_teachers(school:)
        teachers_response = SchoolTeacher::List.call(school:).fetch(:school_teachers, [])

        teachers_response.map do |teacher|
          SchoolMember.new(teacher.id, teacher.name, nil, teacher.email, :teacher, [])
        end
      end

      def fetch_owners(school:)
        owners_response = SchoolOwner::List.call(school:).fetch(:school_owners, [])

        owners_response.map do |owner|
          SchoolMember.new(owner.id, owner.name, nil, owner.email, :owner, [])
        end
      end
    end
  end
end
