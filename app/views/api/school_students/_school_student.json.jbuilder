# frozen_string_literal: true

json.call(
  student,
  :id,
  :username,
  :name
)

json.type(student.type) if student.respond_to?(:type)
