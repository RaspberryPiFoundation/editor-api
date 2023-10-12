# frozen_string_literal: true

require 'operation_response'

class Project
  class CreateShare
    class << self
      def call(params:, user_id:, original_project:)
        response = OperationResponse.new

        validate_params(response, params, original_project)
        share_project(response, params, user_id, original_project) if response.success?
        puts response.inspect
        response
      # rescue StandardError => e
      #   Sentry.capture_exception(e)
      #   response[:error] = I18n.t('errors.project.sharing.cannot_save')
      #   response
      end

      private

      def validate_params(response, params, original_project)
        valid = params[:identifier].present? && original_project.present?
        response[:error] = I18n.t('errors.project.sharing.invalid_params') unless valid
      end

      def share_project(response, params, user_id, original_project)
        response[:project] = create_share(original_project, params, user_id)
        response[:project].save!
        response
      end

      def create_share(original_project, params, user_id)
        share = format_project(original_project, params, user_id)

        original_project.images.each do |image|
          share.images.attach(image.blob)
        end

        params[:components].each do |x|
          share.components.build(x.slice(:name, :extension, :content))
        end

        share
      end

      def format_project(original_project, params, user_id)
        original_project.dup.tap do |proj|
          proj.identifier = PhraseIdentifier.generate
          proj.locale = 'en' # locale validated when user_id nil
          proj.name = params[:name]
          proj.user_id = nil
          proj.remixed_from_id = original_project.id
          proj.is_live = false
        end
      end
    end
  end
end
