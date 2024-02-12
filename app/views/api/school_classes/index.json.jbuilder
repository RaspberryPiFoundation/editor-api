# frozen_string_literal: true

json.array!(@school_classes) do |school_class|
  json.call(
    school_class,
    :id,
    :school_id,
    :teacher_id,
    :name,
    :created_at,
    :updated_at
  )
end
