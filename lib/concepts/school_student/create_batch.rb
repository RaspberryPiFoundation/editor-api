# frozen_string_literal: true

require 'roo'

module SchoolStudent
  class CreateBatch
    class << self
      def call(school:, school_students_params:, token:)
        response = OperationResponse.new
        create_batch(school, school_students_params, token)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = e
        response
      end

      private

      def create_batch(school, students, token)
        validate(students:)
        # TODO: Do the preflight checks here

        CreateStudentsJob.attempt_perform_later(school_id: school.id, students:, token:)
      end

      def validate(students:)
        errors = []
        students.each_with_index do |student, n|
          student_errors = []
          student_errors << "username '#{student[:username]}' is invalid" if student[:username].blank?
          student_errors << "password '#{student[:password]}' is invalid" if student[:password].blank?
          student_errors << "name '#{student[:name]}' is invalid" if student[:name].blank?
          errors << "Error creating student #{n + 1}: #{student_errors.join(', ')}" unless student_errors.empty?
        end
        raise ArgumentError, errors.join(', ') unless errors.empty?
      end
    end
  end
end
