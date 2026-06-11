# frozen_string_literal: true

module Api
  class LessonsController < ApiController
    include RemixSelection
    include LessonCreation

    before_action :authorize_user, except: %i[index show]
    before_action :verify_school_class_belongs_to_school, only: :create
    before_action :verify_can_create_scratch_projects, only: %i[create create_copy]
    load_and_authorize_resource :lesson

    def index
      accessible_lessons = filtered_lessons_scope.accessible_by(current_ability)

      if current_user&.school_teacher?(school) || current_user&.school_owner?(school)
        accessible_lessons = accessible_lessons.includes(:project)
        @lessons_with_users = accessible_lessons.with_users
        render :teacher_index, formats: [:json], status: :ok
      else
        remixes = user_remixes(accessible_lessons)
        accessible_lessons = accessible_lessons.includes(project: :remixes)
        @lessons_with_users_and_remixes = accessible_lessons.with_users.zip(remixes)
        render :student_index, formats: [:json], status: :ok
      end
    end

    def show
      @lesson_with_user = @lesson.with_user
      render :show, formats: [:json], status: :ok
    end

    def create
      result = Lesson::Create.call(lesson_params: create_params)
      if result.success?
        @lesson_with_user = result[:lesson].with_user
        ahoy.track 'Project Created', project_id: 123
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_content
      end
    end

    def create_copy
      result = Lesson::CreateCopy.call(lesson: @lesson, lesson_params: create_params)

      if result.success?
        @lesson_with_user = result[:lesson].with_user
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_content
      end
    end

    def update
      # TODO: Consider removing user_id from the lesson_params for update so users can update other users' lessons without changing ownership
      # OR consider dropping user_id on lessons and using teacher id/ids on the class instead
      result = Lesson::Update.call(lesson: @lesson, lesson_params: update_params)

      if result.success?
        @lesson_with_user = result[:lesson].with_user
        render :show, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_content
      end
    end

    def destroy
      @lesson.destroy!
      head :no_content
    end

    private

    def filtered_lessons_scope
      scope = params[:school_class_id] ? Lesson.where(school_class_id: params[:school_class_id]) : Lesson.all
      scope = scope.joins(:project).where(projects: { identifier: params[:project_identifier] }) if params[:project_identifier].present?
      scope.order(created_at: :asc)
    end

    def verify_school_class_belongs_to_school
      verify_lesson_school_class!(create_params)
    end

    def verify_can_create_scratch_projects
      verify_lesson_scratch!(create_params)
    end

    def user_remixes(lessons)
      lessons.map { |lesson| user_remix(lesson) }
    end

    def user_remix(lesson)
      return nil unless lesson&.project&.remixes&.any?

      remix_for_user(
        lesson.project,
        current_user,
        include_feedback: current_user&.school_student?(school)
      )
    end

    def update_params
      params.fetch(:lesson, {}).permit(
        :name,
        :visibility,
        {
          project_attributes: [:name]
        }
      )
    end

    def create_params
      source = params.fetch(:lesson, {})
      source.permit(*LESSON_ATTRIBUTES, project_attributes: PROJECT_ATTRIBUTES).merge(user_id: current_user.id)
    end

    def school_owner?
      school && current_user.school_owner?(school)
    end

    def school
      @school ||= @lesson&.school || School.find_by(id: create_params[:school_id]) || SchoolClass.find_by(id: params[:school_class_id])&.school
    end
  end
end
