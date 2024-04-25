# frozen_string_literal: true

require 'rails_helper'

RSpec.describe School::Create, type: :unit do
  let(:school_params) do
    {
      name: 'Test School',
      website: 'http://www.example.com',
      address_line_1: 'Address Line 1',
      municipality: 'Greater London',
      country_code: 'GB'
    }
  end

  let(:token) { UserProfileMock::TOKEN }

  before do
    stub_user_info_api
    stub_profile_api_create_organisation
  end

  it 'returns a successful operation response' do
    response = described_class.call(school_params:)
    expect(response.success?).to be(true)
  end

  it 'creates a school' do
    expect { described_class.call(school_params:) }.to change(School, :count).by(1)
  end

  it 'returns the school in the operation response' do
    response = described_class.call(school_params:)
    expect(response[:school]).to be_a(School)
  end

  it 'assigns the name' do
    response = described_class.call(school_params:)
    expect(response[:school].name).to eq('Test School')
  end

  context 'when creation fails' do
    let(:school_params) { {} }

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'does not create a school' do
      expect { described_class.call(school_params:) }.not_to change(School, :count)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school_params:)
      expect(response.failure?).to be(true)
    end

    it 'returns the correct number of objects in the operation response' do
      response = described_class.call(school_params:)
      expect(response[:error].count).to eq(6)
    end

    it 'returns the correct type of object in the operation response' do
      response = described_class.call(school_params:)
      expect(response[:error].first).to be_a(ActiveModel::Error)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school_params:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
