# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OriginParser do
  describe '.parse_origins' do
    after { ENV['ALLOWED_ORIGINS'] = nil }

    it 'returns an empty array if ALLOWED_ORIGINS is not set' do
      ENV['ALLOWED_ORIGINS'] = nil
      expect(described_class.parse_origins).to eq([])
    end

    it 'parses literal strings correctly' do
      ENV['ALLOWED_ORIGINS'] = 'http://example.com, https://example.org'
      expect(described_class.parse_origins).to eq(['http://example.com', 'https://example.org'])
    end

    it 'parses regexes correctly' do
      ENV['ALLOWED_ORIGINS'] = '/https?:\/\/example\.com/'
      expect(described_class.parse_origins).to eq([Regexp.new('https?:\/\/example\.com')])
    end

    it 'parses a mix of literals and regexes' do
      ENV['ALLOWED_ORIGINS'] = 'http://example.com, /https?:\/\/localhost$/'
      expect(described_class.parse_origins).to eq(['http://example.com', Regexp.new('https?:\/\/localhost$')])
    end

    it 'strips whitespace from origins' do
      ENV['ALLOWED_ORIGINS'] = '  http://example.com  , /regex$/  '
      expect(described_class.parse_origins).to eq(['http://example.com', Regexp.new('regex$')])
    end

    it 'returns an empty array if ALLOWED_ORIGINS is empty' do
      ENV['ALLOWED_ORIGINS'] = ''
      expect(described_class.parse_origins).to eq([])
    end
  end
end
