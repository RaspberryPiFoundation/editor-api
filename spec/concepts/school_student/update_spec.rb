# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolStudent::Update, type: :unit do
  let(:token) { UserProfileMock::TOKEN }
  let(:school) { create(:school) }
  let(:student_id) { SecureRandom.uuid }

  let(:school_student_params) do
    {
      username: 'new-username',
      password: 'SaoXlDBAyiAFoMH3VsddhdA7JWnM8P8by1wOjBUWH2g=',
      name: 'New Name'
    }
  end

  before do
    stub_profile_api_update_school_student
  end

  it 'returns a successful operation response' do
    response = described_class.call(school:, student_id:, school_student_params:, token:)
    expect(response.success?).to be(true)
  end

  it 'makes a profile API call' do
    described_class.call(school:, student_id:, school_student_params:, token:)

    # TODO: Replace with WebMock assertion once the profile API has been built.
    expect(ProfileApiClient).to have_received(:update_school_student)
      .with(token:, username: 'new-username', password: 'Student2024', name: 'New Name', school_id: school.id, student_id:)
  end

  context 'when updating fails' do
    let(:school_student_params) do
      {
        username: ' ',
        password: 'SaoXlDBAyiAFoMH3VsddhdA7JWnM8P8by1wOjBUWH2g=',
        name: 'New Name'
      }
    end

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'does not make a profile API request' do
      described_class.call(school:, student_id:, school_student_params:, token:)
      expect(ProfileApiClient).not_to have_received(:update_school_student)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school:, student_id:, school_student_params:, token:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, student_id:, school_student_params:, token:)
      expect(response[:error]).to match(/username ' ' is invalid/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school:, student_id:, school_student_params:, token:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
