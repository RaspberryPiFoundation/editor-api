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
        project_params = lesson_hash[:project_attributes].merge({ user_id: lesson_hash[:user_id],
                                                                  school_id: lesson_hash[:school_id],
                                                                  lesson_id: new_lesson.id })
        new_lesson.project = source_project ? build_remix(source_project, project_params) : Project.new(project_params)
        new_lesson
      end

      def build_remix(source_project, project_params)
        source_project.dup.tap do |remix|
          remix.assign_attributes(remix_attributes(source_project, project_params))
          copy_components(source_project, remix)
          copy_scratch_component(source_project, remix)
          copy_media(source_project, remix)
        end
      end

      def remix_attributes(source_project, project_params)
        {
          identifier: PhraseIdentifier.generate,
          locale: nil,
          name: project_params[:name].presence || source_project.name,
          user_id: project_params[:user_id],
          school_id: project_params[:school_id],
          lesson_id: project_params[:lesson_id],
          remixed_from_id: source_project.id,
          remix_origin: project_params[:remix_origin]
        }
      end

      def copy_components(source_project, remix)
        source_project.components.each do |component|
          remix.components.build(component.attributes.slice('name', 'extension', 'content'))
        end
      end

      def copy_scratch_component(source_project, remix)
        return if source_project.scratch_component.blank?

        remix.build_scratch_component(content: source_project.scratch_component.content.deep_dup)
      end

      def copy_media(source_project, remix)
        source_project.images.each do |image|
          remix.images.attach(image.blob)
        end

        source_project.videos.each do |video|
          remix.videos.attach(video.blob)
        end

        source_project.audio.each do |audio_file|
          remix.audio.attach(audio_file.blob)
        end
      end
    end
  end
end
