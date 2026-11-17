# frozen_string_literal: true

require 'rails_helper'
require 'project_loader'

RSpec.describe ProjectLoader do
  let(:identifier) { PhraseIdentifier.generate }
  let(:preferred_locales) { %w[fr-FR de-DE] }
  let(:loaded_project) do
    described_class.new(
      identifier,
      preferred_locales
    ).load
  end

  context 'when projects exist in both preferred locales' do
    let!(:preferred_project) { create(:project, identifier:, locale: 'fr-FR', user_id: nil) }

    before do
      create(:project, identifier:, locale: 'de-DE', user_id: nil)
    end

    it 'returns the project with the locale highest on list' do
      expect(loaded_project).to eq(preferred_project)
    end
  end

  context 'when project exists in second locale but not first' do
    let!(:preferred_project) { create(:project, identifier:, locale: 'de-DE', user_id: nil) }

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

  context 'when a preferred locale contains unexpected characters' do
    let(:preferred_locales) { ["en-US\u0000/../../../robots.txt"] }
    let!(:english_project) { create(:project, identifier:, locale: 'en') }

    it 'ignores the locale and falls back to en' do
      expect(loaded_project).to eq(english_project)
    end
  end

  context 'when no project with identifier' do
    it 'returns nil' do
      expect(loaded_project).to be_nil
    end
  end
end
