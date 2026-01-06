# frozen_string_literal: true

class SchoolVerificationService
  attr_reader :school

  def initialize(school)
    @school = school
  end

  def verify(token: nil)
    School.transaction do
      school.verify!

      # TODO: Remove this line once the feature flag is retired
      SchoolOnboardingService.new(school).onboard(token: token) unless FeatureFlags.immediate_school_onboarding?
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
