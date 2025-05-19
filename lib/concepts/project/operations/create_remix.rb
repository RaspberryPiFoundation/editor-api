# frozen_string_literal: true

class Project
  class CreateRemix
    class << self
      def call(params:, user_id:, original_project:, remix_origin:)
        response = OperationResponse.new

        validate_params(response, params, user_id, original_project, remix_origin)
        remix_project(response, params, user_id, original_project, remix_origin) if response.success?
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = I18n.t('errors.project.remixing.cannot_save')
        response
      end

      private

      def validate_params(response, params, user_id, original_project, remix_origin)
        valid = (params[:identifier].present? || original_project.identifier.present?) && user_id.present? && original_project.present? && remix_origin.present?
        response[:error] = I18n.t('errors.project.remixing.invalid_params') unless valid
      end

      def remix_project(response, params, user_id, original_project, remix_origin)
        response[:project] = create_remix(original_project, params, user_id, remix_origin)
        response[:project].save!
        response
      end

      def create_remix(original_project, params, user_id, remix_origin)
        remix = format_project(original_project, params, user_id, remix_origin)
        puts("remix: #{remix}")
        original_project.images.each do |image|
          remix.images.attach(image.blob)
        end

        original_project.videos.each do |video|
          remix.videos.attach(video.blob)
        end

        original_project.audio.each do |audio_file|
          remix.audio.attach(audio_file.blob)
        end

        (params[:components] || original_project.components).each do |x|
          remix.components.build(x.slice(:name, :extension, :content))
        end
        pp(remix)

        remix
      end

      def format_project(original_project, params, user_id, remix_origin)
        original_project.dup.tap do |proj|
          proj.identifier = PhraseIdentifier.generate
          proj.locale = nil
          proj.name = params[:name] || original_project.name
          proj.user_id = user_id
          proj.remixed_from_id = original_project.id
          proj.remix_origin = remix_origin
          proj.lesson_id = nil # Only the original can have a lesson id
          proj.school_id = params[:school_id]
        end
      end
    end
  end
end
