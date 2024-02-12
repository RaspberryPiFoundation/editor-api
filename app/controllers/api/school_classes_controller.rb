# frozen_string_literal: true

module Api
  class SchoolClassesController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :school
    load_and_authorize_resource :school_class, through: :school, through_association: :classes

    def show
      render :show, formats: [:json], status: :ok
    end

    def create
      result = SchoolClass::Create.call(school: @school, school_class_params:)

      if result.success?
        @school_class = result[:school_class]
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def update
      school_class = @school.classes.find(params[:id])
      result = SchoolClass::Update.call(school_class:, school_class_params:)

      if result.success?
        @school_class = result[:school_class]
        render :show, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def school_class_params
      if school_owner?
        # The school owner must specify who the class teacher is.
        params.require(:school_class).permit(:teacher_id, :name)
      else
        # A school teacher may only create classes they own.
        params.require(:school_class).permit(:name).merge(teacher_id: current_user.id)
      end
    end

    def school_owner?
      current_user.school_owner?(organisation_id: @school.organisation_id)
    end
  end
end
