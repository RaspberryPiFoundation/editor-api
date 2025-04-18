# frozen_string_literal: true

class Lesson
  class Update
    class << self
      def call(lesson:, lesson_params:)
        ActiveRecord::Base.transaction do
          response = OperationResponse.new
          response[:lesson] = lesson
          response[:lesson].assign_attributes(lesson_params)
          response[:lesson].save!
          if lesson_params[:name].present?
            rename_lesson_project(lesson: response[:lesson], name: lesson_params[:name])
            rename_lesson_remixes(lesson: response[:lesson], name: lesson_params[:name])
          end
          response
        rescue StandardError => e
          Sentry.capture_exception(e)
          errors = response[:lesson].errors.full_messages.join(',')
          response[:error] = "Error updating lesson: #{errors}"
          response
        end
      end

      def rename_lesson_project(lesson:, name:)
        return unless lesson.project

        lesson.project.update!(name:)
      end

      def rename_lesson_remixes(lesson:, name:)
        return unless lesson.project

        lesson_remixes = Project.where(remixed_from_id: lesson.project.id)
        lesson_remixes.each do |remix|
          remix.update!(name:)
        end
      end
    end
  end
end
