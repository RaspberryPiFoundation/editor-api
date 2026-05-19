# frozen_string_literal: true

module Api
  class JoinController < ApiController
    before_action :authorize_user, only: :create
    before_action :find_school_and_class

    def show
      @status = show_status
      render :show, formats: [:json], status: :ok
    end

    def create
      case action_status
      when :wrong_school, :domain_mismatch, :not_a_student
        render json: { error: action_status.to_s }, status: :forbidden
      when :already_member, :owner
        render json: { redirect_url: class_redirect_path }, status: :ok
      when :joinable_as_teacher
        add_user_to_class_as_teacher
        render json: { redirect_url: class_redirect_path }, status: :ok
      else
        add_student_to_school_and_class
        render json: { redirect_url: class_redirect_path }, status: :ok
      end
    end

    private

    def find_school_and_class
      @school_class = SchoolClass.find_by!(join_code: JoinCodeGenerator.normalize(params[:join_code]))
      @school = @school_class.school
    end

    def show_status
      return :unauthenticated unless current_user

      action_status
    end

    def action_status
      @action_status ||= compute_action_status
    end

    def compute_action_status
      return :already_member if user_is_member_of_class?
      return existing_user_join_status if user_has_role_in_school?

      new_user_join_status
    end

    # The user already has a role in this school: which one decides the status.
    def existing_user_join_status
      return :owner if user_is_owner_of_school?
      return :joinable_as_teacher if user_is_teacher_of_school?

      :joinable # student is the only remaining role for this school
    end

    # The user has no role in this school yet: may they join as a new student?
    def new_user_join_status
      return :not_a_student if user_has_non_student_role?
      return :wrong_school if user_in_different_school?
      return :domain_mismatch unless @school.valid_email?(current_user.email)

      :joinable
    end

    def class_redirect_path
      "/school/#{@school.code}/class/#{@school_class.code}"
    end

    def user_is_member_of_class?
      ClassStudent.exists?(school_class: @school_class, student_id: current_user.id) ||
        ClassTeacher.exists?(school_class: @school_class, teacher_id: current_user.id)
    end

    def user_is_owner_of_school?
      Role.exists?(school: @school, user_id: current_user.id, role: Role.roles[:owner])
    end

    def user_is_teacher_of_school?
      Role.exists?(school: @school, user_id: current_user.id, role: Role.roles[:teacher])
    end

    def user_has_role_in_school?
      Role.exists?(school: @school, user_id: current_user.id)
    end

    def user_has_non_student_role?
      Role.where(user_id: current_user.id).where.not(role: Role.roles[:student]).exists?
    end

    def user_in_different_school?
      Role.where(user_id: current_user.id).where.not(school_id: @school.id).exists?
    end

    def add_student_to_school_and_class
      Role.create!(school: @school, user_id: current_user.id, role: :student) unless Role.exists?(school: @school, user_id: current_user.id)
      ClassStudent.create!(school_class: @school_class, student_id: current_user.id)
    end

    def add_user_to_class_as_teacher
      class_teacher = @school_class.teachers.build(teacher_id: current_user.id)
      class_teacher.teacher = current_user
      class_teacher.save!
    end
  end
end
