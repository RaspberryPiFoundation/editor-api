# frozen_string_literal: true

module Api
  class ClassMembersController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :school
    load_and_authorize_resource :school_class, through: :school, through_association: :classes, id_param: :class_id
    load_and_authorize_resource :class_member, through: :school_class, through_association: :members

    def create
      result = ClassMember::Create.call(school_class: @school_class, class_member_params:)

      if result.success?
        @class_member = result[:class_member]
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def class_member_params
      params.require(:class_member).permit(:student_id)
    end
  end
end
