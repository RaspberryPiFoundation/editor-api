# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolStudent::Delete, type: :unit do
  let(:token) { UserProfileMock::TOKEN }
  let(:school) { create(:school) }
  let(:student_index) { user_index_by_role('school-student') }
  let(:student_id) { user_id_by_index(student_index) }

  before do
    stub_profile_api_delete_school_student
  end

  it 'returns a successful operation response' do
    response = described_class.call(school:, student_id:, token:)
    expect(response.success?).to be(true)
  end

  it 'makes a profile API call' do
    described_class.call(school:, student_id:, token:)

    # TODO: Replace with WebMock assertion once the profile API has been built.
    expect(ProfileApiClient).to have_received(:delete_school_student)
      .with(token:, student_id:, organisation_id: school.id)
  end

  context 'when removal fails' do
    before do
      allow(ProfileApiClient).to receive(:delete_school_student).and_raise('Some API error')
      allow(Sentry).to receive(:capture_exception)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school:, student_id:, token:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, student_id:, token:)
      expect(response[:error]).to match(/Some API error/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school:, student_id:, token:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
