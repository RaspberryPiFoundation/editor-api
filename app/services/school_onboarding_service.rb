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
  rescue StandardError => e
    Rails.logger.error { "Failed to onboard school #{school.id}: #{e.message}" }
    raise
  end
end
