# frozen_string_literal: true

class SchoolVerificationService
  attr_reader :school

  def initialize(school)
    @school = school
  end

  # rubocop:disable Metrics/AbcSize
  def verify
    School.transaction do
      school.update!(verified_at: Time.zone.now, rejected_at: nil)
      Role.owner.create(user_id: school.creator_id, school:)
      Role.teacher.create(user_id: school.creator_id, school:)
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
    Rails.logger.error { "Failed to verify school #{@school_id}: #{e.message}" }
    false
  else
    true
  end
  # rubocop:enable Metrics/AbcSize

  def reject
    school.update(verified_at: nil, rejected_at: Time.zone.now)
  end
end
