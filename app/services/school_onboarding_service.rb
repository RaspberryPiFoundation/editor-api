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
      # Profile stores safeguarding flags against the school, so the school must exist there first
      SafeguardingFlagService.create_for_token(token:, school:)
    end
  end
end
