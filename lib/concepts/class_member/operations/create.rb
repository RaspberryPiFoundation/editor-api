# frozen_string_literal: true

class ClassMember
  class Create
    class << self
      def call(school_class:, student_ids:)
        response = OperationResponse.new
        response[:class_members] = []
        student_ids.each do |student_id|
          class_member_params = { student_id: }
          class_member = school_class.members.build(class_member_params)
          class_member.save!
          response[:class_members] << class_member
        rescue StandardError => e
          Sentry.capture_exception(e)
          errors = class_member.errors.full_messages.join(',')
          response[:errors] ||= {}
          response[:errors][student_id] = "Error creating class member for student_id #{student_id}: #{errors}"
        end
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error creating class members"
        response
      end
    end
  end
end
