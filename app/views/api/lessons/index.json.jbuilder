# frozen_string_literal: true

json.array!(@lessons_with_users) do |lesson, user|
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

  if lesson.project
    json.project(
      lesson.project,
      :identifier,
      :project_type
    )
    # json.project.finished(lesson.project.finished) if lesson.project.remixed_from_id.present?
  end

  json.user_name(user&.name)
end
