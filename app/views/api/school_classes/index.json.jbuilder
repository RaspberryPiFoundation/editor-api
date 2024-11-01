# frozen_string_literal: true

json.array!(@school_classes_with_teachers) do |school_class, teacher|
  json.call(
    school_class,
    :id,
    :description,
    :school_id,
    :teacher_id,
    :name,
    :created_at,
    :updated_at
  )

  json.teacher_name(teacher&.name)
end
