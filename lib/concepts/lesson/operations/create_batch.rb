# frozen_string_literal: true

class Lesson
  class CreateBatch
    class << self
      def call(lessons_params:)
        lessons_params.map { |lesson| create_one(lesson) }
      end

      private

      def create_one(lesson_params)
        origin_identifier = lesson_params[:origin_identifier]
        Lesson::Create.call(lesson_params: lesson_params.except(:origin_identifier)).tap do |result|
          result[:origin_identifier] = origin_identifier if origin_identifier.present?
        end
      end
    end
  end
end
