# frozen_string_literal: true

class Lesson
  class CreateCopy
    class << self
      def call(lesson:, lesson_params:)
        response = OperationResponse.new
        response[:lesson] = build_copy(lesson, lesson_params)
        response[:lesson].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        errors = response[:lesson].errors.full_messages.join(',')
        response[:error] = "Error creating copy of lesson: #{errors}"
        response
      end

      private

      # TODO: copy projects
      def build_copy(lesson, lesson_params)
        # puts lesson_params
        copy = Lesson.new(parent: lesson, name: lesson.name, description: lesson.description)
        copy.assign_attributes(lesson_params)
        # copy.project = 
        copy
      end
    end
  end
end
