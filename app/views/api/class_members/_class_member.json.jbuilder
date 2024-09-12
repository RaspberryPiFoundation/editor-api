# frozen_string_literal: true

if class_member.respond_to?(:student_id)
  json.call(
    class_member,
    :id,
    :school_class_id,
    :student_id,
    :created_at,
    :updated_at
  )

  json.student do
    json.call(
      class_member.student,
      :id,
      :username,
      :name
    )
  end
else
  # Teachers are not modelled as ClassMembers
  json.set! :teacher do
    json.call(
      class_member,
      :id,
      :name,
      :email
    )
  end
end
