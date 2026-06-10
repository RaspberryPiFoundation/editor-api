# frozen_string_literal: true

json.array!(@results) do |result|
  if result.success?
    json.partial! 'api/lessons/lesson', lesson: result[:lesson], user: @user
  else
    json.error result[:error]
  end

  json.origin_identifier result[:origin_identifier] if result[:origin_identifier].present?
end
