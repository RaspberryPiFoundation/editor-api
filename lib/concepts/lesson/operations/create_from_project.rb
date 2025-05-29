# frozen_string_literal: true

class Lesson
  class CreateFromProject
    class << self
      def call(lesson_params:, remix_origin:)
        pp 'creating lesson from project!'
        # ActiveRecord::Base.transaction do
        response = OperationResponse.new
        response[:lesson] = build_lesson_from_project(lesson_params, remix_origin)
        response[:lesson].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        pp(e)
        errors = response[:lesson].errors.full_messages.join(',')
        response[:error] = "Error creating remix of lesson: #{errors}"
        response
        # end
      end

      private

      def build_lesson_from_project(lesson_params, remix_origin)
        # original_project = Project.find_by(identifier: lesson_params[:project_identifier])
        # lesson_copy = Lesson.new(name: original_project.name)
        # filtered_params = lesson_params.except(:project_identifier)
        # lesson_copy.assign_attributes(filtered_params)
        # lesson_copy.project = build_project_remix(original_project, lesson_params, remix_origin)

        # lesson_copy
        project = Project.find_by(identifier: lesson_params[:project_identifier])
        lesson = Lesson.new(
          name: project.name)
        lesson.assign_attributes(lesson_params.except(:project_identifier))
        lesson.project = project
        lesson
      end

      # def build_project_remix(original_project, lesson_params, remix_origin)
      #   response = Project::CreateRemix.call(
      #     params: {school_id: lesson_params[:school_id]},
      #     user_id: lesson_params[:user_id],
      #     original_project: original_project,
      #     remix_origin: remix_origin
      #   )
      #   response[:project]
      # end
    end
  end
end