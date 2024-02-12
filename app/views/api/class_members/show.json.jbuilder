# frozen_string_literal: true

json.call(
  @class_member_with_student[0],
  :id,
  :school_class_id,
  :student_id,
  :created_at,
  :updated_at
)

if @class_member_with_student[1]
  json.call(
    @class_member_with_student[1],
    :name,
    :nickname,
    :picture
  )
end
