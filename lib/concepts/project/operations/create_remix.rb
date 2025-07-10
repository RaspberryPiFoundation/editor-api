# frozen_string_literal: true

require 'base64'

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
        response[:error] = "#{I18n.t('errors.project.remixing.cannot_save')}: #{e.message}"
        response
      end

      private

      def validate_params(response, params, user_id, original_project, remix_origin)
        valid = params[:identifier].present? && user_id.present? && original_project.present? && remix_origin.present?
        response[:error] = I18n.t('errors.project.remixing.invalid_params') unless valid
      end

      def remix_project(response, params, user_id, original_project, remix_origin)
        response[:project] = create_remix(original_project, params, user_id, remix_origin)
        response[:project].save!
        response
      end

      def create_remix(original_project, params, user_id, remix_origin)
        remix = format_project(original_project, params, user_id, remix_origin)

        params[:image_list].each do |image|
          if image[:content].present?
            remix.images.attach(io: extract_image_io(image), filename: image[:filename])
          else
            existing_image = find_existing_image(image, original_project)
            remix.images.attach(existing_image.blob) if existing_image
          end
        end

        original_project.videos.each do |video|
          remix.videos.attach(video.blob)
        end

        original_project.audio.each do |audio_file|
          remix.audio.attach(audio_file.blob)
        end

        params[:components].each do |x|
          remix.components.build(x.slice(:name, :extension, :content))
        end

        remix
      end

      def format_project(original_project, params, user_id, remix_origin)
        original_project.dup.tap do |proj|
          proj.identifier = PhraseIdentifier.generate
          proj.locale = nil
          proj.name = params[:name]
          proj.user_id = user_id
          proj.remixed_from_id = original_project.id
          proj.remix_origin = remix_origin
          proj.lesson_id = nil # Only the original can have a lesson id
        end
      end

      def extract_image_io(image)
        StringIO.new(Base64.decode64(image[:content]))
      end

      def find_existing_image(image, original_project)
        original_project.images.find { |img| img.filename.to_s == image[:filename].to_s }
      end
    end
  end
end
