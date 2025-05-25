# frozen_string_literal: true

require 'project_loader'

module Api
  class ProjectsController < ApiController
    before_action :authorize_user, only: %i[create update index destroy]
    before_action :load_project, only: %i[show update destroy show_context]
    before_action :load_projects, only: %i[index]
    load_and_authorize_resource
    before_action :verify_lesson_belongs_to_school, only: :create
    after_action :pagination_link_header, only: %i[index]

    def index
      @paginated_projects = @projects.page(params[:page])
      render index: @paginated_projects, formats: [:json]
    end

    def show
      if !@project.school_id.nil? && @project.lesson_id.nil?
        project_with_user = @project.with_user(@current_user)
        @user = project_with_user[1]
      end

      @project.user_id = @current_user.id if class_teacher?(@project)
      render :show, formats: [:json]
    end

    def create
      result = Project::Create.call(project_hash: project_params, current_user:)

      if result.success?
        @project = result[:project]
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def update
      result = Project::Update.call(project: @project, update_hash: project_params, current_user: @current_user)

      if result.success?
        render :show, formats: [:json]
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
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
      if school_owner?
        # A school owner must specify who the project user is.
        base_params
      else
        # A school teacher may only create projects they own.
        base_params.merge(user_id: current_user&.id)
      end
    end

    def base_params
      params.fetch(:project, {}).permit(
        :school_id,
        :lesson_id,
        :user_id,
        :identifier,
        :name,
        :project_type,
        :locale,
        :instructions,
        {
          components: %i[id name extension content index default]
        },
        parent: {},
        image_list: []
      )
    end

    def school_owner?
      school && current_user.school_owner?(school)
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
