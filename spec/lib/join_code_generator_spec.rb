# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JoinCodeGenerator do
  describe '.generate' do
    it 'matches CDDD-CDDD' do
      expect(described_class.generate).to match(described_class::FORMAT_REGEX)
    end

    it 'uses SecureRandom for each code component' do
      allow(SecureRandom).to receive(:random_number).with(described_class::CONSONANTS.length).and_return(0, 1)
      allow(SecureRandom).to receive(:random_number).with(1000).and_return(123, 456)

      expect(described_class.generate).to eq('B123-C456')
      expect(SecureRandom).to have_received(:random_number).with(described_class::CONSONANTS.length).twice
      expect(SecureRandom).to have_received(:random_number).with(1000).twice
    end
  end

  describe '.normalize' do
    it 'inserts a hyphen for an 8-character alphanumeric input' do
      expect(described_class.normalize('b123c456')).to eq('B123-C456')
    end

    it 'accepts input that already includes a hyphen' do
      expect(described_class.normalize('B123-C456')).to eq('B123-C456')
    end

    it 'returns non-8-character alphanumeric strings unchanged' do
      expect(described_class.normalize('SHORT')).to eq('SHORT')
    end
  end
end
