# frozen_string_literal: true

json.array!(@lessons_with_users) do |lesson, user|
  json.partial! 'lesson', lesson: lesson, user: user
  json.submitted_count(lesson.submitted_count)
end
