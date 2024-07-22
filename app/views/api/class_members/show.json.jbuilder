# frozen_string_literal: true

if defined?(@class_members)
  json.array! @class_members do |class_member|
    json.partial! 'class_member', class_member:
  end
elsif defined?(@class_member)
  json.class_member do
    json.partial! 'class_member', class_member: @class_member
  end
end
