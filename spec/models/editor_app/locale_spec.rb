# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditorApp::Locale do
  describe '.resolve' do
    it 'prefers a supported locale from the path' do
      expect(described_class.resolve(path: 'fr-FR', cookie: 'es-LA')).to eq('fr-FR')
    end

    it 'falls back to the cookie when the path has no locale' do
      expect(described_class.resolve(path: nil, cookie: 'es-LA')).to eq('es-LA')
    end

    it 'falls back to the Accept-Language header when there is no path or cookie' do
      expect(described_class.resolve(accept_language: 'de-DE,fr-FR;q=0.9')).to eq('fr-FR')
    end

    it 'defaults to English when nothing is supported' do
      expect(described_class.resolve(path: 'de-DE', cookie: 'zz', accept_language: 'de-DE')).to eq('en')
    end
  end
end
