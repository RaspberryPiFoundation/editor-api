# frozen_string_literal: true

require 'operation_response'

class Project
  class CreateRemix
    class << self
      def call(params:, user_id:, original_project:)
        response = OperationResponse.new

        validate_params(response, params, user_id, original_project)
        remix_project(response, params, user_id, original_project) if response.success?
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = I18n.t('errors.project.remixing.cannot_save')
        response
      end

      private

      def validate_params(response, params, user_id, original_project)
        valid = params[:identifier].present? && user_id.present? && original_project.present?
        response[:error] = I18n.t('errors.project.remixing.invalid_params') unless valid
      end

      def remix_project(response, params, user_id, original_project)
        response[:project] = create_remix(original_project, params, user_id)
        response[:project].save!
        response
      end

      def create_remix(original_project, params, user_id)
        remix = format_project(original_project, user_id)

        original_project.images.each do |image|
          remix.images.attach(image.blob)
        end

        params[:components].each do |x|
          remix.components.build(x.slice(:name, :extension, :content))
        end

        remix
      end

      def format_project(original_project, user_id)
        original_project.dup.tap do |proj|
          proj.user_id = user_id
          proj.remixed_from_id = original_project.id
          proj.identifier = PhraseIdentifier.generate
          proj.locale = nil
        end
      end
    end
  end
end
