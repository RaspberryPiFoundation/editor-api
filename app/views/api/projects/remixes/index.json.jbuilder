# frozen_string_literal: true

json.array!(@projects_with_users) do |project, user|
  json.call(
    project,
    :identifier,
    :project_type,
    :name,
    :user_id,
    :updated_at,
    :last_edited_at
  )

  json.user_name(user&.name)
  json.finished(project.school_project&.finished)
end
