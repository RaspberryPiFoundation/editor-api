# frozen_string_literal: true

json.array!(@class_members_with_students) do |class_member, student|
  json.call(
    class_member,
    :id,
    :school_class_id,
    :student_id,
    :created_at,
    :updated_at
  )

  json.student_username(student&.username)
  json.student_name(student&.name)
end
