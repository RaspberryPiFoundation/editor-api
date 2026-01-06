# frozen_string_literal: true

class SchoolVerificationService
  attr_reader :school

  def initialize(school)
    @school = school
  end

  def verify(token: nil)
    success = false
    School.transaction do
      school.verify!

      # TODO: Remove this line, once the feature flag is retired
      success = FeatureFlags.immediate_school_onboarding? || SchoolOnboardingService.new(school).onboard(token: token)

      # TODO: Remove this line, once the feature flag is retired
      raise ActiveRecord::Rollback unless success
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
    Rails.logger.error { "Failed to verify school #{@school.id}: #{e.message}" }
    false
  else
    # TODO: Return 'true', once the feature flag is retired
    success
  end

  delegate :reject, to: :school
  delegate :reopen, to: :school
end
