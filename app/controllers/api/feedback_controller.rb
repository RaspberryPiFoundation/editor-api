# frozen_string_literal: true

module Api
  class FeedbackController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :feedback

    def index
      if project.blank? || project.school_project.blank?
        render json: { error: 'School project not found' }, status: :not_found
        return
      end

      # Checks that the user is authorised to read the feedback so that if not we can return a 403 rather than an empty array
      project_feedback.each do |feedback|
        authorize! :read, feedback
      end
      @feedback = project_feedback.accessible_by(current_ability)
      render :index, formats: [:json], status: :ok
    end

    def create
      result = Feedback::Create.call(feedback_params: feedback_create_params)

      if result.success?
        @feedback = result[:feedback]
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def project
      return @project if defined?(@project)

      @project = Project.find_by(identifier: url_params[:identifier])
    end

    def project_feedback
      return @project_feedback if defined?(@project_feedback)

      @project_feedback = if project.blank? || project.school_project.blank?
                            Feedback.none
                          else
                            Feedback.where(school_project_id: project.school_project.id)
                          end

      @project_feedback
    end

    # These params are used to authorize the resource with CanCanCan. The project identifier is sent in the URL,
    # but these params need to match the shape of the feedback object whiich is attached to the SchoolProject,
    # not the Project.
    def feedback_params
      school_project = project&.school_project
      feedback_create_params.except(:identifier).merge(
        school_project_id: school_project&.id
      )
    end

    # These params are used to create the feedback in the Feedback::Create operation. The project_id parameter,
    # which is automatically named by Rails based on the route structure, is renamed to identifier for readability,
    # as it is actually the human-readable project_identifier, not the project_id.
    def feedback_create_params
      base_params.merge(user_id: current_user.id)
    end

    def url_params
      permitted_params = params.permit(:project_id)
      { identifier: permitted_params[:project_id] }
    end

    def base_params
      params.fetch(:feedback, {}).permit(
        :content
      ).merge(url_params)
    end
  end
end
