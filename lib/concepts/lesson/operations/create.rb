# frozen_string_literal: true

class Lesson
  class Create
    class << self
      # When source_project is given, the lesson's project is built as a remix of it instead of a stub.
      def call(lesson_params:, source_project: nil)
        response = OperationResponse.new
        response[:lesson] = build_lesson(lesson_params, source_project)
        response[:lesson].save!
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        if response[:lesson].nil?
          response[:error] = "Error creating lesson #{e}"
        else
          errors = response[:lesson].errors.full_messages.join(',')
          response[:error] = "Error creating lesson: #{errors}"
        end
        response
      end

      private

      def build_lesson(lesson_hash, source_project)
        new_lesson = Lesson.new(lesson_hash.except(:project_attributes))
        project_params = (lesson_hash[:project_attributes] || {}).merge({ user_id: lesson_hash[:user_id],
                                                                          school_id: lesson_hash[:school_id],
                                                                          lesson_id: new_lesson.id })
        new_lesson.project = source_project ? build_copy(source_project, project_params) : Project.new(project_params)
        new_lesson
      end

      def build_copy(source_project, project_params)
        Project::Copying.copy_project(source_project,
                                      attributes: attributes_for_copy(source_project, project_params),
                                      media: %i[images videos audio])
      end

      def attributes_for_copy(source_project, project_params)
        {
          locale: nil,
          name: project_params[:name].presence || source_project.name,
          user_id: project_params[:user_id],
          school_id: project_params[:school_id],
          lesson_id: project_params[:lesson_id],
          source_project_id: source_project.id,
          remixed_from_id: nil,
          remix_origin: nil
        }
      end
    end
  end
end
