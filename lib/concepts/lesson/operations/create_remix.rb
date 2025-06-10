# frozen_string_literal: true

class Lesson
  class CreateRemix
    class << self
      def call(lesson_params:, remix_origin:)
        ActiveRecord::Base.transaction do
          response = OperationResponse.new
          response[:lesson] = build_remix(lesson_params, remix_origin)
          response[:lesson].save!
          response
        rescue StandardError => e
          Sentry.capture_exception(e)
          errors = response[:lesson].errors.full_messages.join(',')
          response[:error] = "Error creating remix of lesson: #{errors}"
          response
        end
      end

      private

      def build_remix(lesson_params, remix_origin)
        original_project = Project.find_by(identifier: lesson_params[:project_identifier])
        lesson_copy = Lesson.new(name: original_project.name)
        filtered_params = lesson_params.except(:project_identifier)
        lesson_copy.assign_attributes(filtered_params)
        lesson_copy.project = build_project_remix(original_project, lesson_params, remix_origin)

        lesson_copy
      end

      def build_project_remix(original_project, lesson_params, remix_origin)
        response = Project::CreateRemix.call(
          params: { school_id: lesson_params[:school_id] },
          user_id: lesson_params[:user_id],
          original_project:,
          remix_origin:
        )
        response[:project]
      end
    end
  end
end
