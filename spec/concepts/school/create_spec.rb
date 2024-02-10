# frozen_string_literal: true

require 'rails_helper'

RSpec.describe School::Create, type: :unit do
  let(:school_params) do
    {
      name: 'Test School',
      owner_id: '11111111-11111111-11111111-11111111',
      address_line_1: 'Address Line 1', # rubocop:disable Naming/VariableNumber
      municipality: 'Greater London',
      country_code: 'GB'
    }
  end

  let(:current_user) { build(:user) }

  before do
    stub_profile_api_create_organisation
  end

  it 'creates a school' do
    expect { described_class.call(school_params:, current_user:) }.to change(School, :count).by(1)
  end

  it 'returns the school in the operation response' do
    response = described_class.call(school_params:, current_user:)
    expect(response[:school]).to be_a(School)
  end

  it 'assigns the name' do
    response = described_class.call(school_params:, current_user:)
    expect(response[:school].name).to eq('Test School')
  end

  it 'assigns the owner_id' do
    response = described_class.call(school_params:, current_user:)
    expect(response[:school].owner_id).to eq(current_user.id)
  end

  it 'assigns the organisation_id' do
    response = described_class.call(school_params:, current_user:)
    expect(response[:school].organisation_id).to eq(ProfileApiMock::ORGANISATION_ID)
  end

  context 'when creation fails' do
    let(:school_params) { {} }

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'does not create a school' do
      expect { described_class.call(school_params:, current_user:) }.not_to change(School, :count)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school_params:, current_user:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school_params:, current_user:)
      expect(response[:error]).to match(/Error creating school/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school_params:, current_user:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
