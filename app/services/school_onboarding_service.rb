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

    create_safeguarding_flags(token:)
  end

  private

  # Runs outside the transaction: a rollback cannot undo the school Profile has already created,
  # and any flag missed here is created by the next action that needs one
  def create_safeguarding_flags(token:)
    SafeguardingFlagService.create_for_token(token:, school:)
  rescue StandardError => e
    Sentry.capture_exception(e)
  end
end
