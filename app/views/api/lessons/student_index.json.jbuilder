# frozen_string_literal: true

json.array!(@lessons_with_users_and_remixes) do |lesson_with_user, remix|
  lesson, user = lesson_with_user
  json.partial! 'lesson', lesson: lesson, user: user
  json.remix_identifier(remix.identifier) if remix.present?
end
