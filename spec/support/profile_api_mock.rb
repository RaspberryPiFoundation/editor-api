# frozen_string_literal: true

module ProfileApiMock
  ORGANISATION_ID = '12345678-1234-1234-1234-123456789abc'

  # TODO: Replace with WebMock HTTP stubs once the profile API has been built.

  def stub_profile_api_create_organisation(organisation_id: ORGANISATION_ID)
    allow(ProfileApiClient).to receive(:create_organisation).and_return(id: organisation_id)
  end

  def stub_profile_api_invite_school_owner
    allow(ProfileApiClient).to receive(:invite_school_owner)
  end

  def stub_profile_api_invite_school_teacher
    allow(ProfileApiClient).to receive(:invite_school_teacher)
  end

  def stub_profile_api_create_school_student(user_id:)
    allow(ProfileApiClient).to receive(:create_school_student).and_return(id: user_id)
  end

  def stub_profile_api_remove_school_owner
    allow(ProfileApiClient).to receive(:remove_school_owner)
  end

  def stub_profile_api_remove_school_teacher
    allow(ProfileApiClient).to receive(:remove_school_teacher)
  end
end
