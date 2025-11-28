# frozen_string_literal: true

json.array!(@lessons_with_users_and_remixes) do |lesson_with_user, remix|
  lesson, user = lesson_with_user
  json.partial! 'lesson', lesson: lesson, user: user
  json.remix_identifier(remix.identifier) if remix.present?
  if remix.present?
    json.status(remix.school_project&.status)
    json.has_unread_feedback(remix.school_project&.unread_feedback?)
    json.remix_identifier(remix.identifier)
  end
end
