# frozen_string_literal: true

json.array!(@lessons_with_users_and_remixes) do |lesson_with_user, remix|
  lesson, user = lesson_with_user
  json.partial! 'lesson', lesson: lesson, user: user
  json.status(lesson.project&.school_project&.status)
  json.unread_feedback_count(remix&.school_project&.feedback&.where(read_at: nil)&.count || 0)
  json.remix_identifier(remix.identifier) if remix.present?
end
