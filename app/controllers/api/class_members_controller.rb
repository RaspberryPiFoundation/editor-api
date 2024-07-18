# frozen_string_literal: true

module Api
  class ClassMembersController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :school
    load_and_authorize_resource :school_class, through: :school, through_association: :classes, id_param: :class_id
    load_and_authorize_resource :class_member, through: :school_class, through_association: :members

    def index
      @class_members = @school_class.members.accessible_by(current_ability)
      student_ids = @class_members.pluck(:student_id)

      result = SchoolStudent::List.call(school: @school, token: current_user.token, student_ids:)

      if result.success?
        @school_students = result[:school_students]
        render :index, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def create
      result = ClassMember::Create.call(school_class: @school_class, class_member_params:)

      if result.success?
        @class_member_with_student = result[:class_member].with_student
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
      params.require(:class_member).permit(student_ids: [])
    end
  end
end
