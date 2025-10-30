# frozen_string_literal: true

json.call(
  @school_project,
  :id,
  :school_id,
  :project_id,
  :status
)

json.identifier(@school_project.project.identifier)