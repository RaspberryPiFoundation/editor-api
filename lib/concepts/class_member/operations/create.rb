# frozen_string_literal: true

class ClassMember
  class Create
    class << self
      def call(school_class:, class_member_params:)
        response = OperationResponse.new
        response[:class_member] = school_class.members.build(class_member_params)
        response[:class_member].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        errors = response[:class_member].errors.full_messages.join(',')
        response[:error] = "Error creating class member: #{errors}"
        response
      end
    end
  end
end
