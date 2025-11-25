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
        students = normalize_student_params(students)
        responses = ProfileApiClient.create_school_students_sso(token:, students:, school_id: school.id)

        create_student_roles(school, responses)
        format_student_responses(responses)
      rescue ProfileApiClient::Student422Error => e
        handle_validations(e.errors)
      end

      def normalize_student_params(students)
        # Ensure that nil values are empty strings, else Profile will swallow validations
        students.map do |student|
          student.transform_values { |value| value.nil? ? '' : value }
        end
      end

      def create_student_roles(school, responses)
        user_ids = responses.pluck(:id)
        existing_user_ids = Role.student.where(school_id: school.id, user_id: user_ids).pluck(:user_id)
        new_user_ids = user_ids - existing_user_ids

        return if new_user_ids.empty?

        # Use insert_all to avoid N+1 INSERT queries
        new_roles = new_user_ids.map do |user_id|
          {
            role: Role.roles[:student],
            school_id: school.id,
            user_id: user_id
          }
        end

        # We know the school and uniqueness is ok at this stage, so we can skip validations
        # rubocop:disable Rails/SkipsModelValidations
        Role.insert_all(new_roles, unique_by: %i[user_id school_id role])
        # rubocop:enable Rails/SkipsModelValidations
      end

      def format_student_responses(responses)
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
