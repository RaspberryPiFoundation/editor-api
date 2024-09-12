# frozen_string_literal: true

json.array!(@class_members) do |class_member|
  json.partial! 'class_member', class_member:
end
