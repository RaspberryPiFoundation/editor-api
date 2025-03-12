# frozen_string_literal: true

module Api
  class ClassMembersController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :school
    load_and_authorize_resource :school_class, through: :school, through_association: :classes, id_param: :class_id
    load_and_authorize_resource :class_student, through: :school_class, through_association: :students

    def index
      @class_students = @school_class.students.accessible_by(current_ability)
      owners = SchoolOwner::List.call(school: @school).fetch(:school_owners, [])
      result = ClassMember::List.call(school_class: @school_class, class_students: @class_students, token: current_user.token)

      if result.success?
        @school_owner_ids = owners.map(&:id)
        @class_members = result[:class_members]
        render :index, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def create
      user_ids = [class_member_params[:user_id]]
      user_type = class_member_params[:type]
      if user_type == 'student'
        teachers = { school_teachers: [] }
        students = SchoolStudent::List.call(school: @school, token: current_user.token, student_ids: user_ids)
      else
        teachers = SchoolTeacher::List.call(school: @school, teacher_ids: user_ids)
        students = { school_students: [] }
      end
      result = ClassMember::Create.call(school_class: @school_class, students: students[:school_students], teachers: teachers[:school_teachers])

      if result.success?
        @class_member = result[:class_members].first
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def create_batch
      # Teacher objects needs to be the compliment of student objects so that every user creation is attempted and validated.
      student_objects = create_batch_params.select { |user| user[:type] == 'student' }
      teacher_objects = create_batch_params.select { |user| student_objects.pluck(:user_id).exclude?(user[:user_id]) }
      student_ids = student_objects.pluck(:user_id)
      teacher_ids = teacher_objects.pluck(:user_id)

      students = list_students(@school, current_user.token, student_ids)
      teachers = list_teachers(@school, teacher_ids)

      result = ClassMember::Create.call(school_class: @school_class, students: students[:school_students], teachers: teachers[:school_teachers])

      if result.success?
        @class_members = result[:class_members]
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def destroy
      result = ClassMember::Delete.call(school_class: @school_class, class_member_id: params[:id])

      if result.success?
        head :no_content
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def class_member_params
      params.require(:class_member).permit(:user_id, :type)
    end

    def create_batch_params
      class_members = params.require(:class_members)

      class_members.map do |class_member|
        next if class_member.blank?

        class_member.permit(:user_id, :type).to_h.with_indifferent_access
      end
    end

    def list_students(school, _token, student_ids)
      if student_ids.present?
        SchoolStudent::List.call(school:, token: current_user.token, student_ids:)
      else
        { school_students: [] }
      end
    end

    def list_teachers(school, teacher_ids)
      if teacher_ids.present?
        SchoolTeacher::List.call(school:, teacher_ids:)
      else
        { school_teachers: [] }
      end
    end
  end
end
