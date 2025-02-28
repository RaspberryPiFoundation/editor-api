# frozen_string_literal: true

module Api
  class ClassMembersController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :school
    load_and_authorize_resource :school_class, through: :school, through_association: :classes, id_param: :class_id
    load_and_authorize_resource :class_student, through: :school_class, through_association: :students

    def index
      @class_students = @school_class.students.accessible_by(current_ability)
      result = ClassMember::List.call(school_class: @school_class, class_students: @class_students, token: current_user.token)

      if result.success?
        @class_members = result[:class_members]
        render :index, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def create
      puts "creating class member", class_member_params
      user_ids = [class_member_params[:user_id]]
      result = ClassMember::Create.call(school_class: @school_class, user_ids:, token: current_user.token)
      pp 'the result is', result

      if result.success?
        @class_member = result[:class_members].first
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def create_batch
      result = ClassMember::Create.call(school_class: @school_class, user_ids: create_batch_params, token: current_user.token)

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
      params.require(:class_member).permit(:user_id)
    end

    def create_batch_params
      params.permit(user_ids: [])
    end
  end
end
