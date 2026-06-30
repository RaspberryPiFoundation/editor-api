# frozen_string_literal: true

source_lesson = @project.lesson || @project.parent&.lesson

json.call(
  @project,
  :identifier,
  :project_type,
  :school_id
)

json.lesson_id source_lesson&.id
json.class_id source_lesson&.school_class_id
