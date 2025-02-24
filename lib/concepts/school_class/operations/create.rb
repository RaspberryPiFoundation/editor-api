# frozen_string_literal: true

class SchoolClass
  class Create
    class << self
      def call(school:, school_class_params:, current_user:)
        response = OperationResponse.new
        response[:school_class] = build_class(school, school_class_params, current_user)
        response[:school_class].save!
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
        new_class.class_teachers.build(teacher_id: current_user.id)
        new_class
      end
    end
  end
end
