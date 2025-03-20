# frozen_string_literal: true

json.call(
  @project,
  :identifier,
  :school_id,
  :lesson_id
)

json.class_id(@project.lesson.school_class_id)