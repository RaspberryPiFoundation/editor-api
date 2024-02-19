# frozen_string_literal: true

module Api
  class LessonsController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :lesson

    def create
      result = Lesson::Create.call(lesson_params:)

      if result.success?
        @lesson = result[:lesson]
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def lesson_params
      params.require(:lesson).permit(:school_id, :school_class_id, :name).merge(user_id: current_user.id)
    end
  end
end
