# frozen_string_literal: true

class ClassMember
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
        class_member = school_class.members.find(class_member_id)
        class_member.destroy!
      end
    end
  end
end
