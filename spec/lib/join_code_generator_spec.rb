# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JoinCodeGenerator do
  describe '.generate' do
    it 'generates a string in CVDDCVDD format' do
      expect(described_class.generate).to match(JoinCodeGenerator::FORMAT_REGEX)
    end

    it 'generates consonant-vowel-digit-digit-consonant-vowel-digit-digit pattern' do
      code = described_class.generate
      consonants = JoinCodeGenerator::CONSONANTS
      vowels = JoinCodeGenerator::VOWELS

      # Check pattern: C-V-DD-C-V-DD
      expect(consonants).to include(code[0])
      expect(vowels).to include(code[1])
      expect(code[2]).to match(/\d/)
      expect(code[3]).to match(/\d/)
      expect(consonants).to include(code[4])
      expect(vowels).to include(code[5])
      expect(code[6]).to match(/\d/)
      expect(code[7]).to match(/\d/)
    end

    it 'generates a different code each time' do
      codes = 10.times.map { described_class.generate }
      expect(codes.uniq.length).to eq(10)
    end

    it 'does not generate codes with offensive patterns' do
      # Generate many codes to check filtering works
      codes = 100.times.map { described_class.generate }
      
      codes.each do |code|
        first_cv = code[0, 2]
        second_cv = code[4, 2]
        
        expect(JoinCodeGenerator::OFFENSIVE_PATTERNS).not_to include(first_cv)
        expect(JoinCodeGenerator::OFFENSIVE_PATTERNS).not_to include(second_cv)
      end
    end
  end
end
