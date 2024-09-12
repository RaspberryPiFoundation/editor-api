# frozen_string_literal: true

module SchoolTeacher
  class List
    class << self
      def call(teacher_ids:)
        response = OperationResponse.new
        response[:school_teachers] = list_teachers(teacher_ids)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error listing school teachers: #{e}"
        response
      end

      private

      def list_teachers(ids)
        User.from_userinfo(ids:)
      end
    end
  end
end
