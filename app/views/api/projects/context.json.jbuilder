# frozen_string_literal: true

json.call(
  @project,
  :identifier,
  :project_type,
  :school_id,
  :lesson_id
)

json.class_id(@project.lesson.school_class_id)
