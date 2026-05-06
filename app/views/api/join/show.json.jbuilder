# frozen_string_literal: true

json.status @status.to_s
json.school do
  json.code @school.code
  json.name @school.name
end
json.school_class do
  json.code @school_class.code
  json.name @school_class.name
end
