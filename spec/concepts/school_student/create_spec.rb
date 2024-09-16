# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolStudent::Create, type: :unit do
  let(:token) { UserProfileMock::TOKEN }
  let(:school) { create(:verified_school) }
  let(:user_id) { SecureRandom.uuid }

  let(:school_student_params) do
    {
      username: 'student-to-create',
      password: 'at-least-8-characters',
      name: 'School Student'
    }
  end

  before do
    stub_profile_api_create_school_student(user_id:)
  end

  it 'returns a successful operation response' do
    response = described_class.call(school:, school_student_params:, token:)
    expect(response.success?).to be(true)
  end

  it 'makes a profile API call' do
    described_class.call(school:, school_student_params:, token:)

    # TODO: Replace with WebMock assertion once the profile API has been built.
    expect(ProfileApiClient).to have_received(:create_school_student)
      .with(token:, username: 'student-to-create', password: 'at-least-8-characters', name: 'School Student', school_id: school.id)
  end

  it 'creates a role associating the student with the school' do
    described_class.call(school:, school_student_params:, token:)
    expect(Role.student.where(school:, user_id:)).to exist
  end

  it 'returns the ID of the student created in Profile API' do
    response = described_class.call(school:, school_student_params:, token:)
    expect(response[:student_id]).to eq(user_id)
  end

  context 'when creation fails' do
    let(:school_student_params) do
      {
        username: '',
        password: 'at-least-8-characters',
        name: 'School Student'
      }
    end

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'does not make a profile API request' do
      described_class.call(school:, school_student_params:, token:)
      expect(ProfileApiClient).not_to have_received(:create_school_student)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school:, school_student_params:, token:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, school_student_params:, token:)
      expect(response[:error]).to match(/username '' is invalid/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school:, school_student_params:, token:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end

  context 'when the school is not verified' do
    let(:school) { create(:school) }

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, school_student_params:, token:)
      expect(response[:error]).to match(/school is not verified/)
    end
  end

  context 'when the student cannot be created in profile api because of a 422 response' do
    let(:error) { { 'message' => "something's up with the username" } }
    let(:exception) { ProfileApiClient::Student422Error.new(error) }

    before do
      allow(ProfileApiClient).to receive(:create_school_student).and_raise(exception)
    end

    it 'adds a useful error message' do
      response = described_class.call(school:, school_student_params:, token:)
      expect(response[:error]).to eq("Error creating school student: something's up with the username")
    end
  end

  context 'when the student cannot be created in profile api because of a response other than 422' do
    before do
      allow(ProfileApiClient).to receive(:create_school_student)
        .and_raise('Student not created in Profile API (status code 401)')
    end

    it 'adds a useful error message' do
      response = described_class.call(school:, school_student_params:, token:)
      expect(response[:error]).to eq('Error creating school student: Student not created in Profile API (status code 401)')
    end
  end
end
