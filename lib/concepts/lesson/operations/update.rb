# frozen_string_literal: true

class Lesson
  class Update
    class << self
      def call(lesson:, lesson_params:, current_user:)
        response = OperationResponse.new
        response[:lesson] = lesson
        response[:lesson].assign_attributes(lesson_params)
        response[:lesson].save!
        if lesson_params[:name].present?
          rename_lesson_project(current_user:, lesson: response[:lesson], name: lesson_params[:name])
          rename_lesson_remixes(current_user:, lesson: response[:lesson], name: lesson_params[:name])
        end
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        errors = response[:lesson].errors.full_messages.join(',')
        response[:error] = "Error updating lesson: #{errors}"
        response
      end

      def rename_lesson_project(current_user:, lesson:, name:)
        return unless lesson.project

        lesson.project.current_user = current_user
        lesson.project.assign_attributes(name:)
        lesson.project.save!
      end

      def rename_lesson_remixes(current_user:, lesson:, name:)
        lesson_remixes = Project.where(remixed_from_id: lesson.project.id)
        lesson_remixes.each do |remix|
          remix.current_user = current_user
          remix.assign_attributes(name:)
          remix.save!
        end
      end
    end
  end
end
