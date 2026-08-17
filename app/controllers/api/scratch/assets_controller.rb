# frozen_string_literal: true

module Api
  module Scratch
    class AssetsController < ApiController
      include ActiveStorage::SetCurrent

      before_action :authorize_user, except: %i[show]
      prepend_before_action :load_project_from_header, only: %i[show create create_global]
      authorize_resource :project_from_header, except: %i[create_global]

      def show
        filename_with_extension = "#{params[:id]}.#{params[:format]}"

        scratch_asset = ScratchAsset.find_visible_to_project(
          project: @project_from_header,
          user: current_user,
          filename: filename_with_extension
        )
        raise ActiveRecord::RecordNotFound, 'Not Found' unless scratch_asset

        redirect_to scratch_asset.file.url(content_type: scratch_asset.response_content_type), allow_other_host: true
      end

      def create
        filename_with_extension = "#{params[:id]}.#{params[:format]}"
        create_asset(
          project: @project_from_header,
          uploaded_user_id: current_user.id,
          filename: filename_with_extension
        )
      end

      def create_global
        authorize! :create, @project_from_header
        raise CanCan::AccessDenied unless experience_cs_public_project?

        create_asset(project: nil, uploaded_user_id: nil, filename: "#{params[:id]}.#{params[:format]}")
      end

      private

      def create_asset(attributes)
        scratch_asset = ScratchAsset.find_or_initialize_by(attributes)

        if scratch_asset.new_record?
          begin
            scratch_asset.save!
          rescue ActiveRecord::RecordNotUnique
            logger.info("Scratch asset already created during concurrent upload: #{attributes.fetch(:filename)}")
            scratch_asset = ScratchAsset.find_by!(attributes)
          end
        end

        scratch_asset.file.attach(io: request.body, filename: attributes.fetch(:filename)) unless scratch_asset.file.attached?

        render json: { status: 'ok', 'content-name': params[:id] }, status: :created
      end

      def experience_cs_public_project?
        current_user.experience_cs_admin? && @project_from_header.user_id.nil? && @project_from_header.school_id.nil?
      end

      def load_project_from_header
        identifier = request.headers['X-Project-ID']
        return render json: { error: 'X-Project-ID header is required' }, status: :bad_request if identifier.blank?

        @project_from_header = Project.find_by!(
          identifier:,
          project_type: Project::Types::CODE_EDITOR_SCRATCH
        )
      end
    end
  end
end
