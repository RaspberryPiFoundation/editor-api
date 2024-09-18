# frozen_string_literal: true

class ClassMember
  class List
    class << self
      def call(school_class:, class_members:, token:)
        response = OperationResponse.new
        response[:class_members] = []

        begin
          school = school_class.school
          student_ids = class_members.pluck(:student_id)
          students = SchoolStudent::List.call(school:, token:, student_ids:).fetch(:school_students, [])
          class_members.each do |member|
            member.student = students.find { |student| student.id == member.student_id }
          end

          teacher_ids = [school_class.teacher_id]
          teachers = SchoolTeacher::List.call(school:, teacher_ids:).fetch(:school_teachers, [])
        rescue StandardError => e
          Sentry.capture_exception(e)
          response[:error] = "Error listing class members: #{e}"
          return response
        end

        response[:class_members] = teachers + class_members.sort do |a, b|
          a.student.name <=> b.student.name
        end

        response
      end
    end
  end
end
