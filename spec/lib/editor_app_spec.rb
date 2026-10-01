# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditorApp do
  describe '.serves_host?' do
    it 'matches a literal host' do
      ClimateControl.modify(EDITOR_APP_HOSTS: 'editor.localhost') do
        expect(described_class.serves_host?('editor.localhost')).to be(true)
        expect(described_class.serves_host?('editor-api.localhost')).to be(false)
      end
    end

    it 'matches a host given as a regex' do
      ClimateControl.modify(EDITOR_APP_HOSTS: '/^editor(-staging)?\.example\.com$/') do
        expect(described_class.serves_host?('editor-staging.example.com')).to be(true)
        expect(described_class.serves_host?('other.example.com')).to be(false)
      end
    end

    it 'serves no hosts when unconfigured' do
      ClimateControl.modify(EDITOR_APP_HOSTS: nil) do
        expect(described_class.serves_host?('editor.localhost')).to be(false)
      end
    end
  end
end
