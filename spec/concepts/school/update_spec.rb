# frozen_string_literal: true

require 'rails_helper'

RSpec.describe School::Update, type: :unit do
  let(:school) { create(:school, name: 'Test School Name') }
  let(:school_params) { { name: 'New Name' } }

  it 'returns a successful operation response' do
    response = described_class.call(school:, school_params:)
    expect(response.success?).to be(true)
  end

  it 'updates the school' do
    response = described_class.call(school:, school_params:)
    expect(response[:school].name).to eq('New Name')
  end

  it 'returns the school in the operation response' do
    response = described_class.call(school:, school_params:)
    expect(response[:school]).to be_a(School)
  end

  context 'when updating fails' do
    let(:school_params) { { name: ' ' } }

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'does not update the school' do
      response = described_class.call(school:, school_params:)
      expect(response[:school].reload.name).to eq('Test School Name')
    end

    it 'returns a failed operation response' do
      response = described_class.call(school:, school_params:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, school_params:)
      expect(response[:error]).to match(/Error updating school/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school:, school_params:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
