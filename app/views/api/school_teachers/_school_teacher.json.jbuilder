# frozen_string_literal: true

json.call(
  teacher,
  :id,
  :name
)

json.type(teacher.type) if teacher.respond_to?(:type)

include_email = local_assigns.fetch(:include_email, true)

json.email(teacher.email) if include_email
