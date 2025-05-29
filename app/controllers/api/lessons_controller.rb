# frozen_string_literal: true

module Api
  class LessonsController < ApiController
    before_action :authorize_user, except: %i[index show]
    before_action :verify_school_class_belongs_to_school, only: :create
    load_and_authorize_resource :lesson, except: [:create_from_project]

    def index
      archive_scope = params[:include_archived] == 'true' ? Lesson : Lesson.unarchived
      scope = params[:school_class_id] ? archive_scope.where(school_class_id: params[:school_class_id]) : archive_scope
      ordered_scope = scope.order(created_at: :asc)
      @lessons_with_users = ordered_scope.accessible_by(current_ability).with_users
      render :index, formats: [:json], status: :ok
    end

    def show
      @lesson_with_user = @lesson.with_user
      render :show, formats: [:json], status: :ok
    end

    def create
      result = Lesson::Create.call(lesson_params:)

      if result.success?
        @lesson_with_user = result[:lesson].with_user
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def create_copy
      result = Lesson::CreateCopy.call(lesson: @lesson, lesson_params:)

      if result.success?
        @lesson_with_user = result[:lesson].with_user
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def create_from_project
      remix_origin = request.origin || request.referer

      result = Lesson::CreateFromProject.call(lesson_params:, remix_origin:)

      if result.success?
        @lesson_with_user = result[:lesson].with_user
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def update
      # TODO: Consider removing user_id from the lesson_params for update so users can update other users' lessons without changing ownership
      # OR consider dropping user_id on lessons and using teacher id/ids on the class instead
      result = Lesson::Update.call(lesson: @lesson, lesson_params:)

      if result.success?
        @lesson_with_user = result[:lesson].with_user
        render :show, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def destroy
      operation = params[:undo] == 'true' ? Lesson::Unarchive : Lesson::Archive
      result = operation.call(lesson: @lesson)

      if result.success?
        head :no_content
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def verify_school_class_belongs_to_school
      return if base_params[:school_class_id].blank?
      return if school&.classes&.pluck(:id)&.include?(base_params[:school_class_id])

      raise ParameterError, 'school_class_id does not correspond to school_id'
    end

    def lesson_params
      base_params.merge(user_id: current_user.id)
    end

    def base_params
      params.fetch(:lesson, {}).permit(
        :school_id,
        :school_class_id,
        :name,
        :description,
        :visibility,
        :due_date,
        :project_identifier,
        {
          project_attributes: [
            :name,
            :project_type,
            :locale,
            { components: %i[id name extension content index default] }
          ]
        }
      )
    end

    def school_owner?
      school && current_user.school_owner?(school)
    end

    def school
      @school ||= @lesson&.school || School.find_by(id: base_params[:school_id])
    end
  end
end
