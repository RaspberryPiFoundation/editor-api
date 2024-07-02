# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProfileApiClient do
  describe '.create_school' do
    let(:api_url) { 'http://example.com' }
    let(:api_key) { 'api-key' }
    let(:token) { SecureRandom.uuid }
    let(:school) { build(:school, id: SecureRandom.uuid, code: SecureRandom.uuid) }
    let(:create_school_url) { "#{api_url}/api/v1/schools" }

    before do
      stub_request(:post, create_school_url).to_return(status: 201, body: '{}')
      allow(ENV).to receive(:fetch).with('IDENTITY_URL').and_return(api_url)
      allow(ENV).to receive(:fetch).with('PROFILE_API_KEY').and_return(api_key)
    end

    it 'makes a request to the profile api host' do
      create_school
      expect(WebMock).to have_requested(:post, create_school_url)
    end

    it 'includes token in the authorization request header' do
      create_school
      expect(WebMock).to have_requested(:post, create_school_url).with(headers: { authorization: "Bearer #{token}" })
    end

    it 'includes the profile api key in the x-api-key request header' do
      create_school
      expect(WebMock).to have_requested(:post, create_school_url).with(headers: { 'x-api-key' => api_key })
    end

    it 'sets content-type of request to json' do
      create_school
      expect(WebMock).to have_requested(:post, create_school_url).with(headers: { 'content-type' => 'application/json' })
    end

    it 'sets accept header to json' do
      create_school
      expect(WebMock).to have_requested(:post, create_school_url).with(headers: { 'accept' => 'application/json' })
    end

    it 'sends the school id and code in the request body as json' do
      create_school
      expected_body = { id: school.id, schoolCode: school.code }.to_json
      expect(WebMock).to have_requested(:post, create_school_url).with(body: expected_body)
    end

    it 'returns the created school if successful' do
      data = { 'id' => 'school-id', 'schoolCode' => 'school-code' }
      stub_request(:post, create_school_url)
        .to_return(status: 201, body: data.to_json)
      expect(create_school).to eq(data)
    end

    it 'raises exception if anything other than a 201 status code is returned' do
      stub_request(:post, create_school_url)
        .to_return(status: 200)

      expect { create_school }.to raise_error(RuntimeError)
    end

    it 'includes details of underlying response when exception is raised' do
      stub_request(:post, create_school_url)
        .to_return(status: 401)

      expect { create_school }.to raise_error('School not created in Profile API. HTTP response code: 401')
    end

    describe 'when BYPASS_OAUTH is true' do
      before do
        allow(ENV).to receive(:[]).with('BYPASS_OAUTH').and_return(true)
      end

      it 'does not make a request to Profile API' do
        create_school
        expect(WebMock).not_to have_requested(:post, create_school_url)
      end

      it 'returns the id and code of the school supplied' do
        expected = { 'id' => school.id, 'schoolCode' => school.code }
        expect(create_school).to eq(expected)
      end
    end

    private

    def create_school
      described_class.create_school(token:, school:)
    end
  end
end
