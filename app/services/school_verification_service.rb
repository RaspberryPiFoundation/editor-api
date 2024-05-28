# frozen_string_literal: true

class SchoolVerificationService
  def initialize(school_id, current_user)
    @school_id = school_id
    @current_user = current_user
  end

  def verify
    School.transaction do
      school = School.find(@school_id)
      school.update(verified_at: Time.zone.now, rejected_at: nil)
      Role.owner.create(user_id: school.creator_id, school:)
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
    Rails.logger.error { "Failed to verify school #{school_id}: #{e.message}" }
    false
  else
    true
  end

  def reject
    school = School.find(@school_id)
    school.update(verified_at: nil, rejected_at: Time.zone.now)
  end
end
