# frozen_string_literal: true

lesson, user = @lesson_with_user

json.partial! 'lesson', lesson:, user:
