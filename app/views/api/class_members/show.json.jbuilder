# frozen_string_literal: true

json.array!(@class_members) do |class_member|
  json.call(
    class_member,
    :id,
    :school_class_id,
    :student_id,
    :created_at,
    :updated_at
  )

  if class_member.student.present?
    json.set! :student do
      json.call(
        class_member.student,
        :id,
        :username,
        :name
      )
    end
  end
end
