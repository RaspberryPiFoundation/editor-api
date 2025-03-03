# frozen_string_literal: true

module SchoolTeacher
  class List
    class << self
      def call(school:, teacher_ids: nil)
        response = OperationResponse.new
        teacher_ids = school.roles.where(role: :teacher)&.pluck(:user_id) if teacher_ids.blank?
        response[:school_teachers] = list_teachers(teacher_ids)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        pp 'the error is', e
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
