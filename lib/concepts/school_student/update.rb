# frozen_string_literal: true

module SchoolStudent
  class Update
    class << self
      def call(school:, school_student_params:, token:)
        response = OperationResponse.new
        update_student(school, school_student_params, token)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error updating school student: #{e}"
        response
      end

      private

      def update_student(school, school_student_params, token)
        username = school_student_params.fetch(:username, nil)
        password = school_student_params.fetch(:password, nil)
        name = school_student_params.fetch(:name, nil)

        validate(username:, password:, name:)

        attributes_to_update = { username:, password:, name: }.compact
        return if attributes_to_update.empty?

        ProfileApiClient.update_school_student(token:, attributes_to_update:, organisation_id: school.id)
      end

      def validate(username:, password:, name:)
        raise ArgumentError, "username '#{username}' is invalid" if !username.nil? && username.blank?
        raise ArgumentError, "password '#{password}' is invalid" if !password.nil? && password.size < 8
        raise ArgumentError, "name '#{name}' is invalid" if !name.nil? && name.blank?
      end
    end
  end
end
