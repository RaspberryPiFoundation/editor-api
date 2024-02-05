# frozen_string_literal: true

require 'rails_helper'

RSpec.describe School::Create, type: :unit do
  let(:school_hash) do
    {
      name: 'Test School',
      organisation_id: '00000000-00000000-00000000-00000000',
      owner_id: '11111111-11111111-11111111-11111111',
      address_line_1: 'Address Line 1', # rubocop:disable Naming/VariableNumber
      municipality: 'Greater London',
      country_code: 'GB'
    }
  end

  it 'creates a school' do
    expect { described_class.call(school_hash:) }.to change(School, :count).by(1)
  end

  it 'returns the school in the operation response' do
    response = described_class.call(school_hash:)
    expect(response[:school]).to be_a(School)
  end

  it 'assigns the name' do
    response = described_class.call(school_hash:)
    expect(response[:school].name).to eq('Test School')
  end

  it 'assigns the organisation_id' do
    response = described_class.call(school_hash:)
    expect(response[:school].organisation_id).to eq('00000000-00000000-00000000-00000000')
  end

  context 'when creation fails' do
    let(:school_hash) { {} }

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'does not create a school' do
      expect { described_class.call(school_hash:) }.not_to change(School, :count)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school_hash:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school_hash:)
      expect(response[:error]).to eq('Error creating school')
    end

    it 'sent the exception to Sentry' do
      described_class.call(school_hash:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
