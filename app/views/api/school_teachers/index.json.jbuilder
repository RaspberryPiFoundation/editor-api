# frozen_string_literal: true

json.array!(@school_teachers) do |teacher|
  json.partial! 'school_teacher', teacher:
end
