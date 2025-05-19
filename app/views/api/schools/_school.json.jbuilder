# frozen_string_literal: true

json.call(
  school,
  :id,
  :name,
  :website,
  :reference,
  :address_line_1,
  :address_line_2,
  :municipality,
  :administrative_area,
  :postal_code,
  :country_code,
  :verified_at,
  :created_at,
  :updated_at
)

include_roles = local_assigns.fetch(:roles, false)
json.roles(roles) if include_roles

include_code = local_assigns.fetch(:code, false)
json.code(school.code) if include_code
