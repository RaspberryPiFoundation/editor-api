# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProfileApiClient do
  describe '.create_school' do
    let(:api_url) { 'http://example.com' }
    let(:api_key) { 'api-key' }
    let(:token) { SecureRandom.uuid }
    let(:school) { build(:school, id: SecureRandom.uuid, code: SecureRandom.uuid) }

    before do
      stub_request(:post, "#{api_url}/api/v1/schools").to_return(status: 201, body: '{}')
      allow(ENV).to receive(:fetch).with('IDENTITY_URL').and_return(api_url)
      allow(ENV).to receive(:fetch).with('PROFILE_API_KEY').and_return(api_key)
    end

    it 'makes a request to the profile api host' do
      described_class.create_school(token:, school:)
      expect(WebMock).to have_requested(:post, "#{api_url}/api/v1/schools")
    end

    it 'includes token in the authorization request header' do
      described_class.create_school(token:, school:)
      expect(WebMock).to have_requested(:post, "#{api_url}/api/v1/schools").with(headers: { authorization: "Bearer #{token}" })
    end

    it 'includes the profile api key in the x-api-key request header' do
      described_class.create_school(token:, school:)
      expect(WebMock).to have_requested(:post, "#{api_url}/api/v1/schools").with(headers: { 'x-api-key' => api_key })
    end

    it 'sets content-type of request to json' do
      described_class.create_school(token:, school:)
      expect(WebMock).to have_requested(:post, "#{api_url}/api/v1/schools").with(headers: { 'content-type' => 'application/json' })
    end

    it 'sets accept header to json' do
      described_class.create_school(token:, school:)
      expect(WebMock).to have_requested(:post, "#{api_url}/api/v1/schools").with(headers: { 'accept' => 'application/json' })
    end

    it 'sends the school id and code in the request body as json' do
      described_class.create_school(token:, school:)
      expected_body = { id: school.id, schoolCode: school.code }.to_json
      expect(WebMock).to have_requested(:post, "#{api_url}/api/v1/schools").with(body: expected_body)
    end

    it 'returns the created school if successful' do
      data = { 'id' => 'school-id', 'schoolCode' => 'school-code' }
      stub_request(:post, "#{api_url}/api/v1/schools")
        .to_return(status: 201, body: data.to_json)
      expect(described_class.create_school(token:, school:)).to eq(data)
    end

    it 'raises exception if anything other than a 201 status code is returned' do
      stub_request(:post, "#{api_url}/api/v1/schools")
        .to_return(status: 200)

      expect { described_class.create_school(token:, school:) }.to raise_error(RuntimeError)
    end

    it 'includes details of underlying response when exception is raised' do
      stub_request(:post, "#{api_url}/api/v1/schools")
        .to_return(status: 401)

      expect { described_class.create_school(token:, school:) }.to raise_error('School not created in Profile API. HTTP response code: 401')
    end
  end
end
