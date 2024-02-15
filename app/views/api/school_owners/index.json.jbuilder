# frozen_string_literal: true

json.array!(@school_owners) do |owner|
  json.call(
    owner,
    :id,
    :email,
    :name
  )
end
