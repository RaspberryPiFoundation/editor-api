# frozen_string_literal: true

json.call(
  school_class,
  :id,
  :description,
  :school_id,
  :name,
  :code,
  :created_at,
  :updated_at,
  :import_origin,
  :import_id
)

json.teachers(teachers) do |teacher|
  json.partial! '/api/school_teachers/school_teacher', teacher:, include_email: false
end
