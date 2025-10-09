module Api
  class FeedbackController < ApiController
    before_action :authorize_user
    # load_and_authorize_resource :feedback

    def create
      puts "create feedback called with params: #{params.inspect}"
      puts "params before being passed in are: #{feedback_params.inspect}"
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
      params.permit(:project_id)
    end

    def base_params
      params.fetch(:feedback, {}).permit(
        :content,
      ).merge(url_params)
    end
  end
end
