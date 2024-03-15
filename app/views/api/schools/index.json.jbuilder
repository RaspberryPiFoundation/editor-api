# frozen_string_literal: true

json.array!(@schools) do |school|
  json.call(
    school,
    :id,
    :name,
    :reference,
    :address_line_1, # rubocop:disable Naming/VariableNumber
    :address_line_2, # rubocop:disable Naming/VariableNumber
    :municipality,
    :administrative_area,
    :postal_code,
    :country_code,
    :verified_at,
    :created_at,
    :updated_at
  )
end
