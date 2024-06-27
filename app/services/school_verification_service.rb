# frozen_string_literal: true

class SchoolVerificationService
  attr_reader :school

  def initialize(school)
    @school = school
  end

  # rubocop:disable Metrics/AbcSize
  def verify(token:)
    School.transaction do
      school.verify!
      Role.owner.create!(user_id: school.creator_id, school:)
      Role.teacher.create!(user_id: school.creator_id, school:)
      ProfileApiClient.create_school(token:, school:)
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
    Rails.logger.error { "Failed to verify school #{@school_id}: #{e.message}" }
    false
  else
    true
  end
  # rubocop:enable Metrics/AbcSize

  delegate :reject, to: :school
end
