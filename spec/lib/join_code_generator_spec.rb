# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JoinCodeGenerator do
  describe '.generate' do
    it 'matches CDDD-CDDD' do
      expect(described_class.generate).to match(described_class::FORMAT_REGEX)
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
