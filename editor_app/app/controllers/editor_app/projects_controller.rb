# frozen_string_literal: true

module EditorApp
  class ProjectsController < ApplicationController
    PAGE_SIZE = 8

    before_action :require_sign_in, except: :show
    before_action :reject_school_students, except: :show

    def index
      authorize! :read, Project
      @projects = own_projects.page(params[:page]).per(PAGE_SIZE)
    end

    def show
      @project = ProjectLoader.new(params[:identifier], [params[:locale]]).load
      raise ActiveRecord::RecordNotFound unless @project

      authorize! :show, @project
      return redirect_to experience_cs_project_url, allow_other_host: true if @project.project_type == Project::Types::SCRATCH

      @script_url = WebComponent.script_url
    end

    def create
      authorize! :create, Project
      response = Project::Create.call(project_hash: new_project_hash, current_user:)
      return redirect_to projects_path, alert: response[:error] if response.failure?

      redirect_to project_path(response[:project].identifier)
    end

    def update
      authorize! :update, project
      response = Project::Update.call(project:, update_hash: { name: project_params[:name] }, current_user:)
      return redirect_to projects_path, alert: response[:error] if response.failure?

      redirect_to projects_path, notice: t('editor_app.projects.renamed')
    end

    def destroy
      authorize! :destroy, project
      project.destroy!
      redirect_to projects_path, notice: t('editor_app.projects.deleted')
    end

    private

    # The same filter as Types::QueryType#projects applied for the React index:
    # personal projects only, never a school or lesson project.
    def own_projects
      Project.accessible_by(current_ability, :show)
             .where(user_id: current_user.id, school_id: nil, lesson_id: nil)
             .order(updated_at: :desc)
    end

    def project
      @project ||= own_projects.find_by!(identifier: params.expect(:identifier))
    end

    def project_params
      params.expect(project: %i[name project_type])
    end

    def new_project_hash
      project_type = project_params[:project_type]
      raise ActionController::BadRequest unless ProjectTemplate.types.include?(project_type)

      {
        name: project_params[:name],
        project_type:,
        user_id: current_user.id,
        components: ProjectTemplate.components(project_type)
      }
    end

    # Experience CS owns the Scratch editor, so its projects are handed back to it.
    def experience_cs_project_url
      "#{ENV.fetch('EXPERIENCE_CS_WEB_URL', nil)}/projects/#{@project.identifier}"
    end

    def require_sign_in
      redirect_to home_path if current_user.nil?
    end

    # School students work in Code Classroom, which owns their project list.
    def reject_school_students
      raise CanCan::AccessDenied if current_user&.student?
    end

    def show_footer?
      action_name != 'show'
    end
  end
end
