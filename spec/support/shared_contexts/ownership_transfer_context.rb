# frozen_string_literal: true

RSpec.shared_context 'with a school owner and nominated teacher' do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:owner) { create(:owner, school:) }
  let(:nominee) { create(:teacher, school:) }
end
