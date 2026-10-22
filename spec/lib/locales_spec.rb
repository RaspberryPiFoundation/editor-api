# frozen_string_literal: true

require 'rails_helper'
require 'locales'

RSpec.describe Locales do
  describe '.load_locales' do
    it 'returns the locales a project may be uploaded in' do
      expect(described_class.load_locales).to include(:en, :'fr-FR', :'ga-IE').and not_include(:'en-US')
    end

    it 'keeps locales added by engines available' do
      I18n.available_locales |= [:'en-US']
      described_class.load_locales

      expect(I18n.available_locales).to include(:'en-US')
    end
  end
end
