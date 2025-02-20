# frozen_string_literal: true

class SchoolClass
  class Create
    class << self
      def call(school:, school_class_params:)
        response = OperationResponse.new
        response[:school_class] = build_class(school, school_class_params)
        response[:school_class].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        errors = response[:school_class].errors.full_messages.join(',')
        response[:error] = "Error creating school class: #{errors}"
        response
      end

      private

      def build_class(school, school_class_params)
        new_class = school.classes.build(school_class_params.except(:teacher_ids))
        if school_class_params[:teacher_ids].present?
          school_class_params[:teacher_ids].each do |teacher_id|
            new_class.class_teachers.build(teacher_id:)
          end
        end
        new_class
      end
    end
  end
end
