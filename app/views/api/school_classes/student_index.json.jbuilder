# frozen_string_literal: true

json.array!(@school_classes_with_teachers_and_unread_counts) do |(school_class, teachers), unread_count|
  json.partial! 'school_class', school_class: school_class, teachers: teachers
  json.unread_feedback_count unread_count
end
