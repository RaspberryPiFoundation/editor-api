# frozen_string_literal: true

class ClassMember
  class Create
    class << self
      def call(school_class:, students:)
        response = OperationResponse.new
        response[:class_members] = []
        raise ArgumentError, 'No valid students provided' if !students || students.empty?
        students.each do |student|
          params = { student_id: student.id }
          class_member = school_class.members.build(params)
          class_member.student = student
          class_member.save!
          response[:class_members] << class_member
        rescue StandardError => e
          Sentry.capture_exception(e)
          errors = class_member.errors.full_messages.join(',')
          response[:errors] ||= {}
          response[:errors][student.id] = "Error creating class member for student_id #{student.id}: #{errors}"
        end
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = e.message || "Error creating class members"
        response
      end
    end
  end
end
