# frozen_string_literal: true

json.array!(@class_members) do |class_member|
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
    json.set! :teacher do
      json.call(
        class_member,
        :id,
        :name,
        :email
      )
    end
  end
end
