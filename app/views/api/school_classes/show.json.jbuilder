# frozen_string_literal: true

school_class, teachers = @school_class_with_teachers

json.call(
  school_class,
  :id,
  :description,
  :school_id,
  :name,
  :code,
  :created_at,
  :updated_at
)

json.teachers(teachers) do |teacher|
  json.partial! '/api/school_teachers/school_teacher', teacher:, include_email: false
end
