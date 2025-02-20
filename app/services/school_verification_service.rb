# frozen_string_literal: true

class SchoolVerificationService
  attr_reader :school

  def initialize(school)
    @school = school
  end

  def verify(token:)
    School.transaction do
      school.verify!
      Role.owner.create!(user_id: school.creator_id, school:)
      Role.teacher.create!(user_id: school.creator_id, school:)
      ProfileApiClient.create_school(token:, id: school.id, code: school.code)
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
    Rails.logger.error { "Failed to verify school #{@school.id}: #{e.message}" }
    false
  else
    true
  end

  delegate :reject, to: :school
  delegate :reopen, to: :school
end
