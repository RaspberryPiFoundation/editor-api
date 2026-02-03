# frozen_string_literal: true

class SchoolOnboardingService
  attr_reader :school

  def initialize(school)
    @school = school
  end

  def onboard(token:)
    School.transaction do
      Role.owner.create!(user_id: school.creator_id, school:)
      Role.teacher.create!(user_id: school.creator_id, school:)

      ProfileApiClient.create_school(token:, id: school.id, code: school.code)
    end
  rescue ProfileApiClient::UnauthorizedError
    # Do not log noise to sentry.
    # TODO: consider returning a separate error here to distinguish from other errors and return 401 from the API, not 422
    Rails.logger.warn { "Failed to onboard school #{@school.id}: user is unauthorized" }
    false
  rescue StandardError => e
    Sentry.capture_exception(e)
    Rails.logger.error { "Failed to onboard school #{@school.id}: #{e.message}" }
    false
  else
    true
  end
end
