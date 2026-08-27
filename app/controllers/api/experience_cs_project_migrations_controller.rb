# frozen_string_literal: true

module Api
  class ExperienceCsProjectMigrationsController < ApiController
    prepend_before_action :load_experience_cs_service_user
    before_action :authorize_user
    before_action :load_project

    def update
      migrate_project!
      render json: {
        identifier: @project.identifier,
        locale: @project.locale,
        project_type: @project.project_type
      }
    rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing => e
      render json: { error: e.message }, status: :unprocessable_content
    end

    private

    def load_project
      @project = Project.find_by!(identifier: params.expect(:id), locale: nil)
    end

    def migrate_project!
      attributes = migration_params
      @project.with_lock do
        authorize! :migrate_from_experience_cs, @project
        @project.update!(
          attributes.slice(:name, :instructions).merge(
            project_type: Project::Types::CODE_EDITOR_SCRATCH
          )
        )
        scratch_component = @project.scratch_component || @project.build_scratch_component
        scratch_component.update!(attributes.require(:scratch_component).slice(:content))
      end
    end

    def migration_params
      params.fetch(:project, {}).permit(
        :name,
        { instructions: [:markdown_content] },
        { scratch_component: { content: {} } }
      )
    end
  end
end
