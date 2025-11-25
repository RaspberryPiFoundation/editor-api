# frozen_string_literal: true

module Api
  class SchoolClassesController < ApiController
    before_action :authorize_user
    before_action :load_and_authorize_school
    before_action :load_and_authorize_school_class

    def index
      school_classes = accessible_school_classes
      school_classes = school_classes.joins(:teachers).where(teachers: { teacher_id: current_user&.id }) if params[:my_classes] == 'true'
      @school_classes_with_teachers = school_classes.with_teachers

      if current_user&.school_teacher?(@school) || current_user&.school_owner?(@school)
        render :teacher_index, formats: [:json], status: :ok
      else
        render :student_index, formats: [:json], status: :ok
      end
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

    def import
      school_class_params = import_school_class_params
      school_students_params = import_school_students_params

      # Find or create the school class
      school_class_result = find_or_create_school_class(school_class_params)

      if school_class_result.success?
        school_class = school_class_result[:school_class]
        @school_class_with_teachers = school_class.with_teachers

        # Create students if class exists
        school_students_result = create_school_students(school_students_params, school_class)
        @school_students = school_students_result[:school_students]
        @school_students_errors = school_students_result[:errors]

        # Assign students to class
        @class_members = assign_students_to_class(school_class, @school_students)

        render :import, formats: [:json], status: :created
      else
        render json: { error: school_class_result[:error] }, status: :unprocessable_entity
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

    def find_or_create_school_class(school_class_params)
      # First try and find the class (in case we're re-importing)
      existing_school_class = SchoolClass.find_by(
        school: @school,
        import_origin: school_class_params[:import_origin],
        import_id: school_class_params[:import_id]
      )

      if existing_school_class.present?
        response = OperationResponse.new
        response[:school_class] = existing_school_class
        return response
      end

      # Create new school class if none exists
      SchoolClass::Create.call(
        school: @school,
        school_class_params: school_class_params,
        current_user:,
        validate_context: :import
      )
    end

    def accessible_school_classes
      if current_user&.school_teacher?(@school) || current_user&.school_owner?(@school)
        @school.classes.accessible_by(current_ability).includes(:lessons)
      else
        @school.classes.accessible_by(current_ability)
      end
    end

    def create_school_students(school_students_params, school_class)
      return { school_students: [], errors: nil } unless school_class.present? && school_students_params.present?

      school_students_result = SchoolStudent::CreateBatchSSO.call(
        school: @school,
        school_students_params: school_students_params,
        current_user:
      )

      {
        school_students: school_students_result[:school_students],
        errors: school_students_result[:errors]
      }
    end

    def assign_students_to_class(school_class, school_students)
      return [] unless school_class.present? && school_students.present? && school_students.any?

      # Extract the student objects for class member creation
      students = school_students.pluck(:student)
      class_members_result = ClassMember::Create.call(school_class:, students:, teachers: [])

      # Put the errors in a more useful format for the response
      class_members_errors = class_members_result[:errors].map do |user_id, error|
        { success: false, student_id: user_id, school_class_id: school_class.id, error: error }
      end

      class_members_result[:class_members] + class_members_errors
    end

    def load_and_authorize_school
      @school = if params[:school_id].match?(/\d\d-\d\d-\d\d/)
                  School.find_by(code: params[:school_id])
                else
                  School.find(params[:school_id])
                end
      authorize! :read, @school
    end

    def load_and_authorize_school_class
      if %w[index create import].include?(params[:action])
        authorize! params[:action].to_sym, SchoolClass
      else
        @school_class = if params[:id].match?(/\d\d-\d\d-\d\d/)
                          @school.classes.find_by(code: params[:id])
                        else
                          @school.classes.find(params[:id])
                        end

        authorize! params[:action].to_sym, @school_class
      end
    end

    def school_class_params
      # A school teacher may only create classes they own.
      params.require(:school_class).permit(:name, :description)
    end

    def import_school_class_params
      params.require(:school_class).permit(:name, :description, :import_origin, :import_id)
    end

    def import_school_students_params
      school_students_data = params[:school_students]
      return [] if school_students_data.blank?

      school_students_data.filter_map do |student|
        next if student.blank?

        student.permit(:name, :email).to_h.with_indifferent_access
      end
    end

    def school_owner?
      current_user.school_owner?(@school)
    end
  end
end
