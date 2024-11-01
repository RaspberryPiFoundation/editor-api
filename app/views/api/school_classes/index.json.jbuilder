# frozen_string_literal: true

json.array!(@school_classes_with_teachers) do |school_class, teachers|
  json.call(
    school_class,
    :id,
    :description,
    :school_id,
    :name,
    :created_at,
    :updated_at
  )

  json.teachers(teachers) do |teacher|
    json.call(
      teacher,
      :id,
      :name
    )
  end
end
