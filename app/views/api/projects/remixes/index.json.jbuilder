# frozen_string_literal: true

json.array!(@projects_with_students) do |project, student|
  json.call(
    project,
    :identifier,
    :project_type,
    :name,
    :user_id,
    :updated_at,
    :last_edited_at
  )

  json.user_name(student&.name)
  json.finished(project.school_project&.finished)
  json.status(project.school_project&.status)
end
