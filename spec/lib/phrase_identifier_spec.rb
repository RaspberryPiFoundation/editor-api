# frozen_string_literal: true

require 'rails_helper'
require 'phrase_identifier'

RSpec.describe PhraseIdentifier do
  describe 'PATTERN' do
    subject(:pattern) { described_class::PATTERN }

    it { is_expected.to match('abc-def-ghi') }
    it { is_expected.to match('123-456-789') }
    it { is_expected.to match('a2c-d5f-g8i') }

    it { is_expected.not_to match('Abc-def-ghi') }
    it { is_expected.not_to match('Abc-def-GHI') }
    it { is_expected.not_to match('abc--def-ghi') }
    it { is_expected.not_to match('-abc-def-ghi') }
    it { is_expected.not_to match('abc-def-ghi-') }
    it { is_expected.not_to match('abc def-ghi') }
    it { is_expected.not_to match(' abc-def-ghi') }
    it { is_expected.not_to match('abc-def-ghi ') }
    it { is_expected.not_to match('abc_def_ghi') }
  end

  describe '#generate' do
    subject(:generate) { described_class.generate }

    context 'when there are words in the database' do
      let(:words) { %w[a b c] }
      let(:phrase_regex) { /^[abc]-[abc]-[abc]$/ }

      before do
        allow(described_class).to receive(:words).and_return(words)
      end

      it { is_expected.to match phrase_regex }
    end

    context 'when using the default words.txt file' do
      it 'returns identifiers conforming to the expected pattern' do
        10.times do
          expect(generate).to match(described_class::PATTERN)
        end
      end
    end

    context 'when there are no available combinations' do
      let(:identifier) { Faker::Verb.base }

      before do
        allow(described_class).to receive(:words).and_return([identifier])
        create(:project, identifier:)
      end

      it { expect { generate }.to raise_exception(PhraseIdentifier::Error) }
    end

    context 'when no words are in the database' do
      before do
        allow(described_class).to receive(:words).and_return([])
      end

      it { expect { generate }.to raise_exception(PhraseIdentifier::Error) }
    end
  end

  describe '#unique?' do
    subject { described_class.unique?(phrase) }

    let(:phrase) { 'Hello? Is it me you\'re looking for?' }

    it { is_expected.to be_truthy }

    context 'when a project exists with the phrase as its identifier' do
      before { create(:project, identifier: phrase) }

      it { is_expected.to be_falsey }
    end
  end
end
