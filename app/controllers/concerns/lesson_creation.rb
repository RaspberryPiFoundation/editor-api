# frozen_string_literal: true

module LessonCreation
  extend ActiveSupport::Concern

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

  private

  def verify_lesson_school_class!(lesson_params)
    school_class_id = lesson_params[:school_class_id]
    return if school_class_id.blank?

    school = School.find_by(id: lesson_params[:school_id])
    return if school&.classes&.exists?(id: school_class_id)

    raise ParameterError, 'school_class_id does not correspond to school_id'
  end

  def verify_lesson_scratch!(lesson_params)
    return unless scratch_project?(lesson_params)

    school = School.find_by(id: lesson_params[:school_id])
    return if school&.scratch_enabled?

    render json: { error: 'Forbidden' }, status: :forbidden
  end

  def scratch_project?(lesson_params)
    lesson_params.dig(:project_attributes, :project_type) == Project::Types::CODE_EDITOR_SCRATCH
  end
end
