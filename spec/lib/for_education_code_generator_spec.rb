# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ForEducationCodeGenerator do
  describe '.generate' do
    it 'uses SecureRandom to generate a random number up to the maximum' do
      allow(SecureRandom).to receive(:random_number).with(ForEducationCodeGenerator::MAX_CODE).and_return(123)

      expect(described_class.generate).to eq('00-01-23')
    end

    it 'generates a string containing 3 pairs of digits' do
      expect(described_class.generate).to match(/\d\d-\d\d-\d\d/)
    end

    it 'generates a different code each time' do
      expect(described_class.generate).not_to eq(described_class.generate)
    end
  end
end
