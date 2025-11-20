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
end

json.user_name(user&.name)