# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecordRequestHostInErrors do
  let(:connection) do
    HttpClient.new('https://api.example.com') do |f|
      f.response :raise_error
    end
  end

  def request_host_from_error
    connection.get('/things')
    nil
  rescue Faraday::Error => e
    e.request_host
  end

  describe '#call' do
    it 'records the host on errors raised by response middleware' do
      stub_request(:get, 'https://api.example.com/things').to_return(status: 500)

      expect(request_host_from_error).to eq('api.example.com')
    end

    it 'records the host on errors raised by the adapter' do
      stub_request(:get, 'https://api.example.com/things').to_timeout

      expect(request_host_from_error).to eq('api.example.com')
    end
  end
end
