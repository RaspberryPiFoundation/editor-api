# frozen_string_literal: true

module SchoolMember
  class List
    SchoolMember = Struct.new(:id, :name, :username, :email, :type)

    class << self
      # rubocop:disable Metrics/CyclomaticComplexity
      def call(school:, token:)
        response = OperationResponse.new
        response[:school_members] = []

        students = teachers = owners = []

        begin
          students_response = SchoolStudent::List.call(school:, token:).fetch(:school_students, [])
          teachers_response = SchoolTeacher::List.call(school:).fetch(:school_teachers, [])
          owners_response = SchoolOwner::List.call(school:).fetch(:school_owners, [])

          students = students_response.map do |student|
            SchoolMember.new(student.id, student.name, student.username, nil, :student)
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

        type_priority = { owner: 0, teacher: 1, student: 2 }
        response[:school_members] = (owners + teachers + students).sort do |a, b|
          [type_priority[a.type], a.name] <=> [type_priority[b.type], b.name]
        end
        response
      end
      # rubocop:disable Metrics/CyclomaticComplexity
    enable
  end
end
