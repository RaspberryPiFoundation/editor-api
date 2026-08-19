# frozen_string_literal: true

require 'project_loader'

module Api
  class ProjectsController < ApiController
    EXPERIENCE_CS_SERVICE_PROJECT_TYPES = [Project::Types::SCRATCH, Project::Types::CODE_EDITOR_SCRATCH].freeze

    prepend_before_action :load_experience_cs_service_user, only: %i[create update]
    before_action :authorize_user, only: %i[create update index destroy]
    before_action :load_project, only: %i[show update destroy show_context]
    before_action :load_projects, only: %i[index]
    load_and_authorize_resource
    before_action :authorize_experience_cs_service_project, only: %i[create update]
    before_action :verify_lesson_belongs_to_school, only: :create
    after_action :pagination_link_header, only: %i[index]

    def index
      @paginated_projects = @projects.page(params[:page])
      render index: @paginated_projects, formats: [:json]
    end

    def show
      track_project_event('Project - Opened', @project) if current_user.present?

      if !@project.school_id.nil? && @project.lesson_id.nil?
        project_with_user = @project.with_student(current_user)
        @user = project_with_user[1]
      end

      @project.user_id = current_user.id if class_teacher?(@project) || school_owner_can_update?(@project)
      render :show, formats: [:json]
    end

    def create
      result = Project::Create.call(project_hash: project_params, current_user:)

      if result.success?
        @project = result[:project]
        track_project_event('Project - Created', @project)
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_content
      end
    end

    def update
      result = Project::Update.call(project: @project, update_hash: project_params)

      if result.success?
        track_project_event('Project - Saved', @project)
        render :show, formats: [:json]
      else
        render json: { error: result[:error] }, status: :unprocessable_content
      end
    end

    def destroy
      @project.destroy
      head :ok
    end

    # Returns the identifier, school_id, lesson_id, and class_id of the project so the full context can be loaded
    def show_context
      render :context, formats: [:json]
    end

    private

    def authorize_experience_cs_service_project
      return unless current_user&.id == ExperienceCsServiceAuthenticator::USER_ID
      return if experience_cs_service_project?

      raise CanCan::AccessDenied
    end

    def experience_cs_service_project?
      return public_scratch_project_attributes?(experience_cs_service_project_attributes) if action_name == 'create'

      public_scratch_project_attributes?(@project.attributes.symbolize_keys) &&
        public_scratch_project_attributes?(experience_cs_service_project_attributes)
    end

    def experience_cs_service_project_attributes
      existing_attributes = if action_name == 'create'
                              { user_id: nil, school_id: nil, project_type: Project.column_defaults['project_type'] }
                            else
                              @project.attributes.symbolize_keys
                            end
      requested_attributes = base_params.slice(:user_id, :school_id, :project_type).to_h.symbolize_keys

      existing_attributes.merge(requested_attributes)
    end

    def public_scratch_project_attributes?(attributes)
      attributes[:user_id].nil? &&
        attributes[:school_id].nil? &&
        EXPERIENCE_CS_SERVICE_PROJECT_TYPES.include?(attributes[:project_type])
    end

    def verify_lesson_belongs_to_school
      return if base_params[:lesson_id].blank?
      return if school&.lessons&.pluck(:id)&.include?(base_params[:lesson_id])

      raise ParameterError, 'lesson_id does not correspond to school_id'
    end

    def load_project
      project_loader = ProjectLoader.new(params[:id], [params[:locale]])
      @project = if action_name == 'show'
                   project_loader.load(include_images: true)
                 else
                   project_loader.load
                 end
    end

    def load_projects
      @projects = Project.where(user_id: current_user&.id).order(updated_at: :desc)
    end

    def project_params
      if school_owner? || current_user&.experience_cs_admin?
        # A school owner or an Experience CS admin must specify who the project user is.
        base_params
      else
        # A school teacher may only create projects they own.
        base_params.merge(user_id: current_user&.id)
      end
    end

    def base_params
      params.fetch(:project, {}).permit(*permitted_project_attributes)
    end

    def permitted_project_attributes
      attributes = [
        :school_id,
        :lesson_id,
        :user_id,
        :identifier,
        :name,
        :locale,
        {
          components: %i[id name extension content index default]
        },
        parent: {},
        image_list: []
      ]
      attributes.push(:instructions, { instructions: [:markdown_content] }) if can_set_instructions?
      attributes.push(:project_type, { scratch_component: { content: {} } }) if can_set_project_type_and_scratch_data?

      attributes
    end

    def can_set_instructions?
      !current_user&.student?
    end

    def can_set_project_type_and_scratch_data?
      action_name == 'create' || current_user&.experience_cs_admin?
    end

    def school_owner?
      school && current_user.school_owner?(school)
    end

    def school_owner_can_update?(project)
      school_owner? && can?(:update, project)
    end

    def class_teacher?(project)
      project.lesson_id.present? && project.lesson.school_class.present? && project.lesson.school_class.teacher_ids.include?(current_user.id)
    end

    def school
      @school ||= @project&.school || School.find_by(id: base_params[:school_id])
    end

    def pagination_link_header
      pagination_links = []
      pagination_links << page_links(first_page, 'first')
      pagination_links << page_links(last_page, 'last')
      pagination_links << page_links(next_page, 'next')
      pagination_links << page_links(prev_page, 'prev')

      pagination_links.compact_blank!
      headers['Link'] = pagination_links.join(', ')
    end

    def page_links(to_page, rel_type)
      return if to_page.nil?

      page_info = "page=#{to_page}"
      "<#{request.base_url}/api/projects?#{page_info}>; rel=\"#{rel_type}\""
    end

    def page
      params.key?(:page) ? params[:page].to_i : 1
    end

    def total_pages
      @projects.page(1).total_pages
    end

    def first_page
      @projects.page(page).first_page? ? nil : 1
    end

    def last_page
      @projects.page(page).last_page? ? nil : total_pages
    end

    def next_page
      @projects.page(page).next_page
    end

    def prev_page
      @projects.page(page).prev_page
    end
  end
end
