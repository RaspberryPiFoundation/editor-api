# frozen_string_literal: true

json.call(
  @school_project,
  :id,
  :school_id,
  :project_id,
  :finished
)

json.identifier(@school_project.project.identifier)
