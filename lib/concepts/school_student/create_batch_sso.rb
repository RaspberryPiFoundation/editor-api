# frozen_string_literal: true

module SchoolStudent
  class ValidationError < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super
    end
  end

  class CreateBatchSSO
    class << self
      def call(school:, school_students_params:, current_user:)
        response = OperationResponse.new
        response[:school_students] = []
        response[:school_students] = create_batch_sso(school, school_students_params, current_user.token)
        response
      rescue ValidationError => e
        response[:error] = "Error creating one or more students - see 'errors' key for details"
        response[:errors] = e.errors
        response[:error_type] = :validation_error
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error importing the class or creating students: #{e}"
        response[:error_type] = :standard_error
        response
      end

      private

      def create_batch_sso(school, students, token)
        # Ensure that nil values are empty strings, else Profile will swallow validations
        students = students.map do |student|
          student.transform_values { |value| value.nil? ? '' : value }
        end

        responses = ProfileApiClient.create_school_students_sso(token:, students:, school_id: school.id)

        responses.each do |student|
          Role.student.find_or_create_by(school_id: school.id, user_id: student[:id])
        end

        # Convert hash responses to User objects with separate metadata
        # This separates student data from metadata (success, error, created flags)
        responses.map do |student_data|
          {
            student: User.new(student_data.slice(:id, :name, :email)),
            success: student_data[:success],
            error: student_data[:error],
            created: student_data[:created]
          }
        end
      rescue ProfileApiClient::Student422Error => e
        handle_validations(e.errors)
      end

      def handle_validations(errors)
        formatted_errors = errors.each_with_object({}) do |error, hash|
          name = error['path']
          hash[name] = error['errorCode'] || error['message']
        end

        raise ValidationError, formatted_errors
      end
    end
  end
end
