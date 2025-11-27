# frozen_string_literal: true

json.array!(@school_classes_with_teachers) do |school_class, teachers|
  json.partial! 'school_class', school_class: school_class, teachers: teachers
end
