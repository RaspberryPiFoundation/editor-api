# frozen_string_literal: true

module Api
  class SchoolClassesController < ApiController
    before_action :authorize_user
    before_action :load_school
    before_action :load_school_class, only: %i[show update destroy]
    # before_action :load_school_class

    def index
      school_classes = @school.classes.accessible_by(current_ability)
      school_classes = school_classes.joins(:teachers).where(teachers: { teacher_id: current_user.id }) if params[:my_classes] == 'true'
      @school_classes_with_teachers = school_classes.with_teachers
      render :index, formats: [:json], status: :ok
    end

    def show
      @school_class_with_teachers = @school_class.with_teachers
      render :show, formats: [:json], status: :ok
    end

    def create
      result = SchoolClass::Create.call(school: @school, school_class_params:, current_user:)

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

    def load_school
      @school = if params[:school_id].match?(/\d\d-\d\d-\d\d/)
                  School.find_by(code: params[:school_id])
                else
                  School.find(params[:school_id])
                end
      authorize! :read, @school
    end

    def load_school_class
      @school_class = if params[:id].match?(/\d\d-\d\d-\d\d/)
                        @school.classes.find_by(code: params[:id])
                      else
                        @school.classes.find(params[:id])
                      end
      # pp 'authorizing for action', params[:action].to_sym
      authorize! params[:action].to_sym, @school_class
    end

    def school_class_params
      # A school teacher may only create classes they own.
      params.require(:school_class).permit(:name, :description)
    end

    def school_owner?
      current_user.school_owner?(@school)
    end
  end
end
