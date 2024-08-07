# frozen_string_literal: true

json.call(
  @school,
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
  :code,
  :verified_at,
  :created_at,
  :updated_at
)
json.roles @user.school_roles(@school)
