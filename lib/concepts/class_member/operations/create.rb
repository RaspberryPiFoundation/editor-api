# frozen_string_literal: true

module ClassMember
  class Create
    class << self
      def call(school_class:, students:)
        response = OperationResponse.new
        response[:class_members] = []
        response[:errors] = {}
        raise ArgumentError, 'No valid students provided' if students.blank?

        create_class_members(school_class:, students:, response:)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error creating class members: #{e.message}"
        response
      end

      private

      def create_class_members(school_class:, students:, response:)
        students.each do |student|
          class_student = school_class.students.build({ student_id: student.id })
          class_student.student = student
          class_student.save!
          response[:class_members] << class_student
        rescue StandardError => e
          handle_class_member_error(e, class_student, student, response)
          response
        end
      end

      def handle_class_member_error(exception, class_member, student, response)
        Sentry.capture_exception(exception)
        errors = class_member.errors.full_messages.join(',')
        response[:errors][student.id] = "Error creating class member for student_id #{student.id}: #{errors}"
      end
    end
  end
end
