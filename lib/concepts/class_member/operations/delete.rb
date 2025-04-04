# frozen_string_literal: true

module ClassMember
  class Delete
    class << self
      def call(school_class:, class_member_id:)
        response = OperationResponse.new
        delete_class_member(school_class, class_member_id)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error deleting class member: #{e}"
        response
      end

      private

      def delete_class_member(school_class, class_member_id)
        class_member = school_class.students.find(class_member_id)
        class_member.destroy!
      end
    end
  end
end
