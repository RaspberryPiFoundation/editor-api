# frozen_string_literal: true

json.array!(@feedback) do |feedback|
  json.partial! 'feedback', feedback:
end
