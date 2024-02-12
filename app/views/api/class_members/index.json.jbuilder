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

  if student
    json.call(
      student,
      :name,
      :nickname,
      :picture
    )
  end
end
