# frozen_string_literal: true

school_class, teacher = @school_class_with_teacher

json.call(
  school_class,
  :id,
  :school_id,
  :teacher_id,
  :name,
  :created_at,
  :updated_at
)

json.teacher_name(teacher&.name)
