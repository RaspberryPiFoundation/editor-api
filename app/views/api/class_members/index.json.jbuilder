# frozen_string_literal: true

json.array!(@class_members, @school_students) do |class_member|
  json.call(
    class_member,
    :id,
    :school_class_id,
    :student_id,
    :created_at,
    :updated_at
  )

  school_student = @school_students.find { |student| student.id == class_member.student_id }

  if school_student.present?
    json.set! :student do
      json.call(
        school_student,
        :id,
        :username,
        :name
      )
    end
  end
end
