# frozen_string_literal: true

class SchoolVerificationService
  attr_reader :school

  def initialize(school)
    @school = school
  end

  def verify(token:)
    success = false
    School.transaction do
      school.verify!

      success = SchoolOnboardingService.new(school).onboard(token: token)
      raise ActiveRecord::Rollback unless success
    end

    success
  rescue StandardError => e
    Sentry.capture_exception(e)
    Rails.logger.error { "Failed to verify school #{@school.id}: #{e.message}" }
    false
  end

  delegate :reject, to: :school
  delegate :reopen, to: :school
end
