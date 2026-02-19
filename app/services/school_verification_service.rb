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

      if FeatureFlags.immediate_school_onboarding?
        # For backwards compatibility with pre-Immediate Onboarding unverified schools, we need to create the roles
        #  if they don't exist - this didn't happen at the time the school was created.
        creator_id = school.creator_id
        Role.owner.find_or_create_by!(user_id: creator_id, school:)
        Role.teacher.find_or_create_by!(user_id: creator_id, school:)
        success = true
      else
        success = SchoolOnboardingService.new(school).onboard(token: token)
      end

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
