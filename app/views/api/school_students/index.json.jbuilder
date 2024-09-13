# frozen_string_literal: true

json.array!(@school_students) do |student|
  json.partial! 'school_student', student:
end
