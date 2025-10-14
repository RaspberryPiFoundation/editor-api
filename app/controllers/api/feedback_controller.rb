module Api
  class FeedbackController < ApiController
    before_action :authorize_user
    # load_and_authorize_resource :feedback

    def create
      result = Feedback::Create.call(feedback_params:)

      if result.success?
        @feedback = result[:feedback]
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def feedback_params
      base_params.merge(user_id: current_user.id)
    end

    def url_params
      permitted_params = params.permit(:project_id)
      { identifier: permitted_params[:project_id] }
    end

    # def school_project_params
    #   project_params = params.permit(:project_id)
    #   school_project = Project.find_by(identifier: project_params[:project_id])&.school_project
    #   {school_project_id: school_project&.id}
    # end

    def base_params
      params.fetch(:feedback, {}).permit(
        :content,
      ).merge(url_params)
    end
  end
end
