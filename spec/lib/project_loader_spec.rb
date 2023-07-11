# frozen_string_literal: true

require 'rails_helper'
require 'project_loader'

RSpec.describe ProjectLoader, :sample_words do
  let(:identifier) { PhraseIdentifier.generate }
  let(:preferred_locales) { %w[locale1 locale2] }
  let(:loaded_project) do
    described_class.new(
      identifier,
      preferred_locales
    ).load
  end

  context 'when projects exist in both preferred locales' do
    let!(:preferred_project) { create(:project, identifier:, locale: 'locale1', user_id: nil) }

    before do
      create(:project, identifier:, locale: 'locale2', user_id: nil)
    end

    it 'returns the project with the locale highest on list' do
      expect(loaded_project).to eq(preferred_project)
    end
  end

  context 'when project exists in second locale but not first' do
    let!(:preferred_project) { create(:project, identifier:, locale: 'locale2', user_id: nil) }

    it 'returns the project with the locale highest on list' do
      expect(loaded_project).to eq(preferred_project)
    end
  end

  context 'when English project with identifier exists' do
    let!(:english_project) { create(:project, identifier:, locale: 'en') }

    it 'defaults to en' do
      expect(loaded_project).to eq(english_project)
    end
  end

  context 'when no preferred locale or English versions but user version exists' do
    let!(:user_project) { create(:project, identifier:, locale: nil) }

    it 'loads user project' do
      expect(loaded_project).to eq(user_project)
    end
  end

  context 'when no project with identifier' do
    it 'returns nil' do
      expect(loaded_project).to be_nil
    end
  end
end
