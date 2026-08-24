# frozen_string_literal: true

require 'digest/md5'

module Api
  module Scratch
    class AssetsController < ApiController
      include ActiveStorage::SetCurrent

      prepend_before_action :load_experience_cs_service_user, only: :create_global
      prepend_before_action :load_project_asset_context, only: %i[show create]
      before_action :authorize_user, except: %i[show]
      before_action :authorize_project_from_header, except: %i[create_global]

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
          uploaded_user_id: asset_uploader_id,
          filename: filename_with_extension,
          reject_conflicting_content: current_user.experience_cs_service_account?
        )
      end

      def create_global
        authorize! :create_global, ScratchAsset

        create_asset(
          project: nil,
          uploaded_user_id: nil,
          filename: "#{params[:id]}.#{params[:format]}",
          reject_conflicting_content: true
        )
      end

      private

      def create_asset(reject_conflicting_content: false, **attributes)
        scratch_asset = ScratchAsset.find_or_initialize_by(attributes)

        if scratch_asset.new_record?
          begin
            scratch_asset.save!
          rescue ActiveRecord::RecordNotUnique
            logger.info("Scratch asset already created during concurrent upload: #{attributes.fetch(:filename)}")
            scratch_asset = ScratchAsset.find_by!(attributes)
          end
        end

        if reject_conflicting_content
          return if attach_file_with_conflict_check(scratch_asset, attributes.fetch(:filename)) == :conflict
        else
          attach_file_unless_present(scratch_asset, attributes.fetch(:filename))
        end

        render json: { status: 'ok', 'content-name': params[:id] }, status: :created
      end

      def attach_file_with_conflict_check(scratch_asset, filename)
        scratch_asset.with_lock do
          if scratch_asset.file.attached?
            next :unchanged if file_matches?(scratch_asset)

            next reject_conflicting_file(scratch_asset)
          end

          scratch_asset.file.attach(io: request.body, filename:)
          :attached
        end
      end

      def attach_file_unless_present(scratch_asset, filename)
        scratch_asset.file.attach(io: request.body, filename:) unless scratch_asset.file.attached?
      end

      def file_matches?(scratch_asset)
        scratch_asset.file.blob.checksum == request_body_checksum
      end

      def reject_conflicting_file(scratch_asset)
        scope = scratch_asset.global? ? 'global' : 'project'
        render json: { error: "Asset content conflicts with the existing #{scope} asset" }, status: :conflict
        :conflict
      end

      def request_body_checksum
        @request_body_checksum ||= Digest::MD5.base64digest(request.body.read)
      ensure
        request.body.rewind
      end

      def load_project_asset_context
        authenticate_experience_cs_service_asset_upload if action_name == 'create'

        load_project_from_header
      end

      def authenticate_experience_cs_service_asset_upload
        return if request.headers[ExperienceCsServiceAuthenticator::HEADER].blank?

        load_experience_cs_service_user
        raise CanCan::AccessDenied unless current_user&.experience_cs_service_account?
      end

      def load_project_from_header
        identifier = request.headers['X-Project-ID']
        return render json: { error: 'X-Project-ID header is required' }, status: :bad_request if identifier.blank?

        project_scope = Project.where(identifier:)
        project_scope = project_scope.where(locale: nil) if current_user&.experience_cs_service_account?
        @project_from_header = project_scope.first!
        return if project_accepts_asset_upload?(@project_from_header)

        raise ActiveRecord::RecordNotFound, 'Not Found'
      end

      def authorize_project_from_header
        action = current_user&.experience_cs_service_account? ? :upload_migration_asset : :show
        authorize!(action, @project_from_header)
      end

      def project_accepts_asset_upload?(project)
        return project.experience_cs_migration_target? if current_user&.experience_cs_service_account?

        project.scratch_project?
      end

      def asset_uploader_id
        return @project_from_header.user_id if current_user.experience_cs_service_account?

        current_user.id
      end
    end
  end
end
