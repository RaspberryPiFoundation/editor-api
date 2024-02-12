# frozen_string_literal: true

class_member, student = @class_member_with_student

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
