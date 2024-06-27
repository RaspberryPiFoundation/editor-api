# frozen_string_literal: true

lesson, user = @lesson_with_user

json.call(
  lesson,
  :id,
  :school_id,
  :school_class_id,
  :copied_from_id,
  :user_id,
  :name,
  :description,
  :visibility,
  :due_date,
  :archived_at,
  :created_at,
  :updated_at
)

json.project(
  lesson.project,
  :identifier,
  :project_type
)

json.user_name(user&.name)
