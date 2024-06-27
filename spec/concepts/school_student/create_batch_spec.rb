# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolStudent::CreateBatch, type: :unit do
  let(:token) { UserProfileMock::TOKEN }
  let(:school) { create(:verified_school) }
  let(:file) { fixture_file_upload('students.csv') }

  before do
    stub_profile_api_create_school_student
  end

  it 'returns a successful operation response' do
    response = described_class.call(school:, uploaded_file: file, token:)
    expect(response.success?).to be(true)
  end

  it "makes a profile API call to create Jane Doe's account" do
    described_class.call(school:, uploaded_file: file, token:)

    # TODO: Replace with WebMock assertion once the profile API has been built.
    expect(ProfileApiClient).to have_received(:create_school_student)
      .with(token:, username: 'jane123', password: 'secret123', name: 'Jane Doe', organisation_id: school.id)
  end

  it "makes a profile API call to create John Doe's account" do
    described_class.call(school:, uploaded_file: file, token:)

    # TODO: Replace with WebMock assertion once the profile API has been built.
    expect(ProfileApiClient).to have_received(:create_school_student)
      .with(token:, username: 'john123', password: 'secret456', name: 'John Doe', organisation_id: school.id)
  end

  context 'when an .xlsx file is provided' do
    let(:file) { fixture_file_upload('students.xlsx') }

    it 'returns a successful operation response' do
      response = described_class.call(school:, uploaded_file: file, token:)
      expect(response.success?).to be(true)
    end
  end

  context 'when creation fails' do
    let(:file) { fixture_file_upload('test_image_1.png') }

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'does not make a profile API request' do
      described_class.call(school:, uploaded_file: file, token:)
      expect(ProfileApiClient).not_to have_received(:create_school_student)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school:, uploaded_file: file, token:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, uploaded_file: file, token:)
      expect(response[:error]).to match(/can't detect the type/i)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school:, uploaded_file: file, token:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end

  context 'when the school is not verified' do
    let(:school) { create(:school) }

    it 'returns a failed operation response' do
      response = described_class.call(school:, uploaded_file: file, token:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, uploaded_file: file, token:)
      expect(response[:error]).to match(/school is not verified/)
    end
  end

  context 'when the file contains invalid data' do
    let(:file) { fixture_file_upload('students-invalid.csv') }

    it 'returns a failed operation response' do
      response = described_class.call(school:, uploaded_file: file, token:)
      expect(response.failure?).to be(true)
    end

    it 'returns all of the validation errors in the operation response' do
      response = described_class.call(school:, uploaded_file: file, token:)
      expect(response[:error]).to match(/password 'invalid' is invalid, name ' ' is invalid, username '  '/)
    end

    it 'does not make a profile API request' do
      described_class.call(school:, uploaded_file: file, token:)
      expect(ProfileApiClient).not_to have_received(:create_school_student)
    end
  end
end
