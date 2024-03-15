# frozen_string_literal: true

json.array!(@school_teachers) do |teacher|
  json.call(
    teacher,
    :id,
    :email,
    :name
  )
end
