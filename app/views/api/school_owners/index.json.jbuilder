# frozen_string_literal: true

json.array!(@school_owners) do |owner|
  json.partial! 'school_owner', owner:
end
