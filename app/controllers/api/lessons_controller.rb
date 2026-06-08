# frozen_string_literal: true

module Api
  class LessonsController < ApiController
    include RemixSelection

    LESSON_ATTRIBUTES = %i[
      school_id
      school_class_id
      name
      description
      visibility
      due_date
    ].freeze

    PROJECT_ATTRIBUTES = [
      :name,
      :project_type,
      :locale,
      { components: %i[id name extension content index default] },
      { scratch_component: {} }
    ].freeze

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
      if params[:lesson_projects].present?
        @results = Lesson::CreateBulk.call(
          lessons_params: params[:lesson_projects].map { |entry| bulk_create_params(entry) }
        )
        @user = current_user
        render :create_bulk, formats: [:json], status: :created
      else
        result = Lesson::Create.call(lesson_params: create_params)
        if result.success?
          @lesson_with_user = result[:lesson].with_user
          render :show, formats: [:json], status: :created
        else
          render json: { error: result[:error] }, status: :unprocessable_content
        end
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
      if params[:lesson_projects].present?
        params[:lesson_projects].each { |lesson_params| verify_lesson_school_class!(lesson_params) }
      else
        verify_lesson_school_class!(create_params)
      end
    end

    def verify_lesson_school_class!(lesson_params)
      school_class_id = lesson_params[:school_class_id]
      return if school_class_id.blank?

      school = School.find_by(id: lesson_params[:school_id])
      return if school&.classes&.exists?(id: school_class_id)

      raise ParameterError, 'school_class_id does not correspond to school_id'
    end

    def verify_can_create_scratch_projects
      if params[:lesson_projects].present?
        scratch_project_params = params[:lesson_projects].find { |lesson_params| scratch_project?(lesson_params) }
        return unless scratch_project_params

        verify_lesson_scratch!(scratch_project_params)
      else
        verify_lesson_scratch!(create_params)
      end
    end

    def verify_lesson_scratch!(lesson_params)
      return unless scratch_project?(lesson_params)

      school = School.find_by(id: lesson_params[:school_id])
      return if school&.scratch_enabled?

      render json: { error: 'Forbidden' }, status: :forbidden
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

    def scratch_project?(lesson_params)
      lesson_params.dig(:project_attributes, :project_type) == Project::Types::CODE_EDITOR_SCRATCH
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

    def bulk_create_params(lesson_project)
      permit_lesson_params(lesson_project, :origin_identifier).merge(user_id: current_user.id)
    end

    def create_params
      permit_lesson_params(params.fetch(:lesson, {})).merge(user_id: current_user.id)
    end

    def permit_lesson_params(source, *extra)
      source.permit(*LESSON_ATTRIBUTES, *extra, project_attributes: PROJECT_ATTRIBUTES)
    end

    def school_owner?
      school && current_user.school_owner?(school)
    end

    def school
      @school ||= @lesson&.school || School.find_by(id: create_params[:school_id]) || SchoolClass.find_by(id: params[:school_class_id])&.school
    end
  end
end
