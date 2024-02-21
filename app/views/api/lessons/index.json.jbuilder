# frozen_string_literal: true

json.array!(@lessons_with_users) do |lesson, user|
  json.call(
    lesson,
    :id,
    :school_id,
    :school_class_id,
    :user_id,
    :name,
    :visibility,
    :due_date,
    :created_at,
    :updated_at
  )

  json.user_name(user&.name)
end
