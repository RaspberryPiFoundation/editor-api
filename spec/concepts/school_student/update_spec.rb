# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolStudent::Update, type: :unit do
  let(:token) { UserProfileMock::TOKEN }
  let(:school) { create(:school) }
  let(:student_index) { user_index_by_role('school-student') }
  let(:student_id) { user_id_by_index(student_index) }

  let(:school_student_params) do
    {
      username: 'new-username',
      password: 'new-password',
      name: 'New Name'
    }
  end

  before do
    stub_profile_api_update_school_student
  end

  it 'returns a successful operation response' do
    response = described_class.call(school:, school_student_params:, token:)
    expect(response.success?).to be(true)
  end

  it 'makes a profile API call' do
    described_class.call(school:, school_student_params:, token:)

    # TODO: Replace with WebMock assertion once the profile API has been built.
    expect(ProfileApiClient).to have_received(:update_school_student)
      .with(token:, attributes_to_update: school_student_params, organisation_id: school.id)
  end

  context 'when updating fails' do
    let(:school_student_params) do
      {
        username: ' ',
        password: 'new-password',
        name: 'New Name'
      }
    end

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'does not make a profile API request' do
      described_class.call(school:, school_student_params:, token:)
      expect(ProfileApiClient).not_to have_received(:update_school_student)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school:, school_student_params:, token:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, school_student_params:, token:)
      expect(response[:error]).to match(/username ' ' is invalid/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school:, school_student_params:, token:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
