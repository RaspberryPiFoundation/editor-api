# frozen_string_literal: true

class SchoolClass
  class Create
    class << self
      def call(school:, school_class_params:, current_user:, validate_context: nil)
        response = OperationResponse.new
        response[:school_class] = build_class(school, school_class_params, current_user)
        # validate_context allows us to specify a custom validation context (e.g. :import)
        # when saving the model, so only the relevant validations run.
        response[:school_class].save!(context: validate_context)
        response
      rescue ArgumentError => e
        # Handle invalid enum assignment gracefully, as we can't rely on the standard validation
        raise unless e.message.include?('is not a valid')

        response[:error] = "Error creating school class: #{e.message}"
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        errors = response[:school_class].errors.full_messages.join(',')
        response[:error] = "Error creating school class: #{errors}"
        response
      end

      private

      def build_class(school, school_class_params, current_user)
        new_class = school.classes.build(school_class_params)
        new_class.teachers.build(teacher_id: current_user.id)
        new_class
      end
    end
  end
end
