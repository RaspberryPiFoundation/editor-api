# frozen_string_literal: true

json.array!(@schools) do |school|
  json.partial! 'school', school:
end
