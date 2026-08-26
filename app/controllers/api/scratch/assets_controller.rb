# frozen_string_literal: true

require 'digest/md5'

module Api
  module Scratch
    class AssetsController < ApiController
      include ActiveStorage::SetCurrent

      prepend_before_action :load_experience_cs_service_user, only: %i[create_global create_migration]
      before_action :authorize_user, except: %i[show]
      prepend_before_action :load_project_from_header, only: %i[show create]
      authorize_resource :project_from_header, except: %i[create_global create_migration]
      before_action :load_migration_project, only: :create_migration
      before_action :authorize_migration_asset, only: :create_migration

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

      def create_migration
        create_asset(
          project: @migration_project,
          uploaded_user_id: @migration_project.user_id,
          filename: "#{params[:id]}.#{params[:format]}",
          reject_conflicting_content: true
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

      def load_project_from_header
        identifier = request.headers['X-Project-ID']
        return render json: { error: 'X-Project-ID header is required' }, status: :bad_request if identifier.blank?

        @project_from_header = Project.find_by!(
          identifier:,
          project_type: Project::Types::CODE_EDITOR_SCRATCH
        )
      end

      def load_migration_project
        @migration_project = Project.find_by!(
          identifier: params.expect(:project_id),
          locale: nil
        )
      end

      def authorize_migration_asset
        authorize! :upload_migration_asset, @migration_project
      end
    end
  end
end
