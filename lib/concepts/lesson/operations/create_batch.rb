# frozen_string_literal: true

class Lesson
  class CreateBatch
    class << self
      def call(lessons_params:, source_projects: [])
        lessons_params.zip(source_projects).map { |lesson_params, source_project| create_one(lesson_params, source_project) }
      end

      private

      def create_one(lesson_params, source_project)
        origin_identifier = lesson_params[:origin_identifier]
        Lesson::Create.call(
          lesson_params: lesson_params.except(:origin_identifier, :source_project_identifier),
          source_project:
        ).tap do |result|
          result[:origin_identifier] = origin_identifier if origin_identifier.present?
        end
      end
    end
  end
end
