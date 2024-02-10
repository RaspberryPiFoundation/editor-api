# frozen_string_literal: true

module ProfileApiMock
  ORGANISATION_ID = '12345678-1234-1234-1234-123456789abc'

  # TODO: Replace with a WebMock HTTP stub once the profile API has been built.
  def stub_profile_api_create_organisation(organisation_id: ORGANISATION_ID)
    allow(ProfileApiClient).to receive(:create_organisation).and_return(id: organisation_id)
  end
end
