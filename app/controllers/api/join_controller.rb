# frozen_string_literal: true

module Api
  class JoinController < ApiController
    before_action :authorize_user, only: :create
    before_action :find_school_and_class
    # Join-code flow is governed by JoinStatusService rather than CanCan.
    skip_authorization_check only: %i[show create]

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
      when :joinable
        add_student_to_school_and_class
        render json: { redirect_url: class_redirect_path }, status: :ok
      else
        raise "Unexpected join action_status: #{action_status.inspect}"
      end
    end

    private

    def find_school_and_class
      @school_class = SchoolClass.find_by!(join_code: JoinCodeGenerator.normalize(params.expect(:join_code)))
      @school = @school_class.school
    end

    def show_status
      return :unauthenticated unless current_user

      action_status
    end

    def action_status
      @action_status ||= JoinStatusService.new(school: @school, school_class: @school_class, user: current_user).call
    end

    def class_redirect_path
      "/school/#{@school.code}/class/#{@school_class.code}"
    end

    def add_student_to_school_and_class
      ActiveRecord::Base.transaction do
        Role.find_or_create_by!(school: @school, user_id: current_user.id, role: :student)
        ClassStudent.find_or_create_by!(school_class: @school_class, student_id: current_user.id) do |class_student|
          class_student.student = current_user
        end
      end
    rescue ActiveRecord::RecordNotUnique
      # Concurrent join request for the same user/class — DB unique index
      # caught a race we couldn't catch at validation time. Already enrolled.
    rescue ActiveRecord::RecordInvalid => e
      raise unless e.record.errors.of_kind?(:student_id, :taken)
      # Concurrent join request raced the in-memory uniqueness validator. Already enrolled.
    end

    def add_user_to_class_as_teacher
      ClassTeacher.find_or_create_by!(school_class: @school_class, teacher_id: current_user.id) do |class_teacher|
        class_teacher.teacher = current_user
      end
    rescue ActiveRecord::RecordNotUnique
      # Concurrent join request for the same teacher/class — already enrolled.
    rescue ActiveRecord::RecordInvalid => e
      raise unless e.record.errors.of_kind?(:teacher_id, :taken)
      # Concurrent join raced the in-memory uniqueness validator. Already enrolled.
    end
  end
end
