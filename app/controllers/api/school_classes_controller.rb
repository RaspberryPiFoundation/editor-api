# frozen_string_literal: true

module Api
  class SchoolClassesController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :school
    load_and_authorize_resource :school_class, through: :school, through_association: :classes

    def index
      @school_classes_with_teachers = @school.classes.accessible_by(current_ability).with_teachers
      render :index, formats: [:json], status: :ok
    end

    def show
      @school_class_with_teachers = @school_class.with_teachers
      render :show, formats: [:json], status: :ok
    end

    def create
      result = SchoolClass::Create.call(school: @school, school_class_params:)

      if result.success?
        @school_class_with_teachers = result[:school_class].with_teachers
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def update
      school_class = @school.classes.find(params[:id])
      result = SchoolClass::Update.call(school_class:, school_class_params:)

      if result.success?
        @school_class_with_teachers = result[:school_class].with_teachers
        render :show, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def destroy
      result = SchoolClass::Delete.call(school: @school, school_class_id: params[:id])

      if result.success?
        head :no_content
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def school_class_params
      # A school teacher may only create classes they own.
      params.require(:school_class).permit(:name, :description).merge(teacher_id: current_user.id)
    end

    def school_owner?
      current_user.school_owner?(@school)
    end
  end
end
