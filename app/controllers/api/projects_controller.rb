# frozen_string_literal: true

module Api
  class ProjectsController < ApiController
    before_action :require_oauth_user, only: %i[create update index destroy]
    before_action :load_project, only: %i[show update destroy]
    before_action :load_projects, only: %i[index]
    after_action :pagination_link_header, only: [:index]
    load_and_authorize_resource
    skip_load_resource only: :create

    def index
      @paginated_projects = @projects.page(params[:page]).per(8)
      render index: @paginated_projects, formats: [:json]
    end

    def show
      render :show, formats: [:json]
    end

    def create
      project_hash = project_params.merge(user_id: current_user)
      result = Project::Create.call(project_hash:)

      if result.success?
        @project = result[:project]
        render :show, formats: [:json]
      else
        render json: { error: result[:error] }, status: :internal_server_error
      end
    end

    def update
      update_hash = project_params.merge(user_id: current_user)
      result = Project::Update.call(project: @project, update_hash:)

      if result.success?
        render :show, formats: [:json]
      else
        render json: { error: result[:error] }, status: :bad_request
      end
    end

    def destroy
      @project.destroy
      head :ok
    end

    private

    def load_project
      @project = Project.find_by!(identifier: params[:id])
    end

    def load_projects
      @projects = Project.where(user_id: current_user)
    end

    def project_params
      params.fetch(:project, {}).permit(
        :identifier,
        :name,
        :project_type,
        {
          image_list: [],
          components: %i[id name extension content index default]
        }
      )
    end

    def pagination_link_header
      pagination_links = []
      pagination_links << page_links(1, 'first') if total_pages > 1 && !first_page
      pagination_links << page_links(total_pages, 'last') if total_pages > 1 && !last_page
      pagination_links << page_links(page + 1, 'next') unless last_page
      pagination_links << page_links(page - 1, 'prev') unless first_page

      headers['Link'] = pagination_links.join('; ')
    end

    def page_links(to_page, rel_type)
      page_info = "page=#{to_page}"
      "<#{request.base_url}/api/projects?#{page_info}>, rel=\"#{rel_type}\""
    end

    def page
      params.key?(:page) ? params[:page].to_i : 1
    end

    def total_pages
      @projects.page(1).per(8).total_pages
    end

    def first_page
      @projects.page(page).per(8).first_page?
    end

    def last_page
      @projects.page(page).per(9).last_page?
    end
  end
end
