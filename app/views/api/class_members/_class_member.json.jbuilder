# frozen_string_literal: true

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
    json.partial! '/api/school_students/school_student', student: class_member.student
  end
end
