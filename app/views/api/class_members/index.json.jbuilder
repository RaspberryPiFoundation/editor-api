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

  json.student_name(student&.name)
  json.student_nickname(student&.nickname)
  json.student_picture(student&.picture)
end
