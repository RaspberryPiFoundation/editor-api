# frozen_string_literal: true

json.array!(@school_students) do |student|
  json.call(
    student,
    :id,
    :username,
    :name
  )
end
