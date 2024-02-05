# frozen_string_literal: true

json.call(
  @school,
  :organisation_id,
  :owner_id,
  :address_line_1, # rubocop:disable Naming/VariableNumber
  :address_line_2, # rubocop:disable Naming/VariableNumber
  :municipality,
  :administrative_area,
  :postal_code,
  :country_code,
  :name,
  :verified_at
)
