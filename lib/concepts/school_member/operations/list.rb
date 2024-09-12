# frozen_string_literal: true

class SchoolMember
  class List
    class << self
      def call(school:, token:)
        response = OperationResponse.new
        response[:school_members] = []

        begin
          students = SchoolStudent::List.call(school:, token:).fetch(:school_students, [])
          teachers = SchoolTeacher::List.call(school:).fetch(:school_teachers, [])
        rescue StandardError => e
          Sentry.capture_exception(e)
          response[:error] = "Error listing class members: #{e}"
          return response
        end

        response[:school_members] = students + teachers
        response
      end
    end
  end
end
