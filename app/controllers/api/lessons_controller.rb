# frozen_string_literal: true

module Api
  class LessonsController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :school, if: :school
    load_and_authorize_resource :school_class, if: :school_class
    load_and_authorize_resource :lesson

    def create
      result = Lesson::Create.call(school:, school_class:, lesson_params:, current_user:)

      if result.success?
        @lesson = result[:lesson]
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def school
      @school ||= School.find_by(id: lesson_params[:school_id])
    end

    def school_class
      @school_class ||= SchoolClass.find_by(id: lesson_params[:school_class_id])
    end

    def lesson_params
      params.require(:lesson).permit(:name)
    end
  end
end
