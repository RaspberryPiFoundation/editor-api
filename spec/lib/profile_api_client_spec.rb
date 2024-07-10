# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProfileApiClient do
  let(:api_url) { 'http://example.com' }
  let(:api_key) { 'api-key' }
  let(:token) { SecureRandom.uuid }

  before do
    allow(ENV).to receive(:fetch).with('IDENTITY_URL').and_return(api_url)
    allow(ENV).to receive(:fetch).with('PROFILE_API_KEY').and_return(api_key)
  end

  describe ProfileApiClient::Student422Error do
    subject(:exception) { described_class.new(error) }

    let(:error_code) { 'ERR_USER_EXISTS' }
    let(:error) { { 'username' => 'username', 'error' => error_code } }

    it 'includes status code, username and translated error code in the message' do
      expect(exception.message).to eq("Student not saved in Profile API (status code 422, username 'username', error 'username has already been taken')")
    end

    context "when the error isn't recognised" do
      let(:error_code) { 'unrecognised-code' }

      it 'includes a default error message' do
        expect(exception.message).to match(/error 'unknown error'/)
      end
    end
  end

  describe '.create_school' do
    let(:school) { build(:school, id: SecureRandom.uuid, code: SecureRandom.uuid) }
    let(:create_school_url) { "#{api_url}/api/v1/schools" }

    before do
      stub_request(:post, create_school_url)
        .to_return(
          status: 201,
          body: '{"id":"","schoolCode":"","updatedAt":"","createdAt":"","discardedAt":""}',
          headers: { 'content-type' => 'application/json' }
        )
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
      data = { id: 'id', schoolCode: 'code', updatedAt: '2024-07-09T10:31:13.196Z', createdAt: '2024-07-09T10:31:13.196Z', discardedAt: nil }
      expected = ProfileApiClient::School.new(**data)
      stub_request(:post, create_school_url)
        .to_return(status: 201, body: data.to_json, headers: { 'Content-Type' => 'application/json' })
      expect(create_school).to eq(expected)
    end

    it 'raises exception if anything other than a 201 status code is returned' do
      stub_request(:post, create_school_url)
        .to_return(status: 200)

      expect { create_school }.to raise_error(RuntimeError, 'School not created in Profile API (status code 200)')
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
      described_class.create_school(token:, id: school.id, code: school.code)
    end
  end

  describe '.safeguarding_flags' do
    let(:list_safeguarding_flags_url) { "#{api_url}/api/v1/safeguarding-flags" }

    before do
      stub_request(:get, list_safeguarding_flags_url).to_return(status: 200, body: '[]', headers: { 'content-type' => 'application/json' })
    end

    it 'makes a request to the profile api host' do
      list_safeguarding_flags
      expect(WebMock).to have_requested(:get, list_safeguarding_flags_url)
    end

    it 'includes token in the authorization request header' do
      list_safeguarding_flags
      expect(WebMock).to have_requested(:get, list_safeguarding_flags_url).with(headers: { authorization: "Bearer #{token}" })
    end

    it 'includes the profile api key in the x-api-key request header' do
      list_safeguarding_flags
      expect(WebMock).to have_requested(:get, list_safeguarding_flags_url).with(headers: { 'x-api-key' => api_key })
    end

    it 'sets accept header to json' do
      list_safeguarding_flags
      expect(WebMock).to have_requested(:get, list_safeguarding_flags_url).with(headers: { 'accept' => 'application/json' })
    end

    # rubocop:disable RSpec/ExampleLength
    it 'returns list of safeguarding flags if successful' do
      flag = {
        id: '7ac79585-e187-4d2f-bf0c-a1cbe72ecc9a',
        userId: '583ba872-b16e-46e1-9f7d-df89d267550d',
        flag: 'school:owner',
        email: 'user@example.com',
        createdAt: '2024-07-01T12:49:18.926Z',
        updatedAt: '2024-07-01T12:49:18.926Z',
        discardedAt: nil
      }
      expected = ProfileApiClient::SafeguardingFlag.new(**flag)
      stub_request(:get, list_safeguarding_flags_url)
        .to_return(status: 200, body: [flag].to_json, headers: { 'content-type' => 'application/json' })
      expect(list_safeguarding_flags).to eq([expected])
    end
    # rubocop:enable RSpec/ExampleLength

    it 'raises exception if anything other than a 200 status code is returned' do
      stub_request(:get, list_safeguarding_flags_url)
        .to_return(status: 201)

      expect { list_safeguarding_flags }.to raise_error(RuntimeError, 'Safeguarding flags cannot be retrieved from Profile API (status code 201)')
    end

    private

    def list_safeguarding_flags
      described_class.safeguarding_flags(token:)
    end
  end

  describe '.create_safeguarding_flag' do
    let(:flag) { 'school:owner' }
    let(:create_safeguarding_flag_url) { "#{api_url}/api/v1/safeguarding-flags" }

    before do
      stub_request(:post, create_safeguarding_flag_url).to_return(status: 201, body: '{}', headers: { 'content-type' => 'application/json' })
    end

    it 'makes a request to the profile api host' do
      create_safeguarding_flag
      expect(WebMock).to have_requested(:post, create_safeguarding_flag_url)
    end

    it 'includes token in the authorization request header' do
      create_safeguarding_flag
      expect(WebMock).to have_requested(:post, create_safeguarding_flag_url).with(headers: { authorization: "Bearer #{token}" })
    end

    it 'includes the profile api key in the x-api-key request header' do
      create_safeguarding_flag
      expect(WebMock).to have_requested(:post, create_safeguarding_flag_url).with(headers: { 'x-api-key' => api_key })
    end

    it 'sets content-type of request to json' do
      create_safeguarding_flag
      expect(WebMock).to have_requested(:post, create_safeguarding_flag_url).with(headers: { 'content-type' => 'application/json' })
    end

    it 'sets accept header to json' do
      create_safeguarding_flag
      expect(WebMock).to have_requested(:post, create_safeguarding_flag_url).with(headers: { 'accept' => 'application/json' })
    end

    it 'sends the safeguarding flag in the request body' do
      create_safeguarding_flag
      expect(WebMock).to have_requested(:post, create_safeguarding_flag_url).with(body: { flag: }.to_json)
    end

    it 'returns empty body if created successfully' do
      stub_request(:post, create_safeguarding_flag_url)
        .to_return(status: 201)
      expect(create_safeguarding_flag).to be_nil
    end

    it 'returns empty body if 303 response returned to indicate that the flag already exists' do
      stub_request(:post, create_safeguarding_flag_url)
        .to_return(status: 303)
      expect(create_safeguarding_flag).to be_nil
    end

    it 'raises exception if anything other than a 201 or 303 status code is returned' do
      stub_request(:post, create_safeguarding_flag_url)
        .to_return(status: 200)

      expect { create_safeguarding_flag }.to raise_error(RuntimeError, 'Safeguarding flag not created in Profile API (status code 200)')
    end

    def create_safeguarding_flag
      described_class.create_safeguarding_flag(token:, flag:)
    end
  end

  describe '.delete_safeguarding_flag' do
    let(:flag) { 'school:owner' }
    let(:delete_safeguarding_flag_url) { "#{api_url}/api/v1/safeguarding-flags/#{flag}" }

    before do
      stub_request(:delete, delete_safeguarding_flag_url).to_return(status: 204, body: '')
    end

    it 'makes a request to the profile api host' do
      delete_safeguarding_flag
      expect(WebMock).to have_requested(:delete, delete_safeguarding_flag_url)
    end

    it 'includes token in the authorization request header' do
      delete_safeguarding_flag
      expect(WebMock).to have_requested(:delete, delete_safeguarding_flag_url).with(headers: { authorization: "Bearer #{token}" })
    end

    it 'includes the profile api key in the x-api-key request header' do
      delete_safeguarding_flag
      expect(WebMock).to have_requested(:delete, delete_safeguarding_flag_url).with(headers: { 'x-api-key' => api_key })
    end

    it 'sets accept header to json' do
      delete_safeguarding_flag
      expect(WebMock).to have_requested(:delete, delete_safeguarding_flag_url).with(headers: { 'accept' => 'application/json' })
    end

    it 'returns empty body if successful' do
      stub_request(:delete, delete_safeguarding_flag_url)
        .to_return(status: 204, body: '')
      expect(delete_safeguarding_flag).to be_nil
    end

    it 'raises exception if anything other than a 204 status code is returned' do
      stub_request(:delete, delete_safeguarding_flag_url)
        .to_return(status: 200)

      expect { delete_safeguarding_flag }.to raise_error(RuntimeError, 'Safeguarding flag not deleted from Profile API (status code 200)')
    end

    def delete_safeguarding_flag
      described_class.delete_safeguarding_flag(token:, flag:)
    end
  end

  describe '.create_school_student' do
    let(:username) { 'username' }
    let(:password) { 'password' }
    let(:name) { 'name' }
    let(:school) { build(:school, id: SecureRandom.uuid) }
    let(:create_students_url) { "#{api_url}/api/v1/schools/#{school.id}/students" }

    before do
      stub_request(:post, create_students_url).to_return(status: 201, body: '{}', headers: { 'content-type' => 'application/json' })
    end

    it 'makes a request to the profile api host' do
      create_school_student
      expect(WebMock).to have_requested(:post, create_students_url)
    end

    it 'includes token in the authorization request header' do
      create_school_student
      expect(WebMock).to have_requested(:post, create_students_url).with(headers: { authorization: "Bearer #{token}" })
    end

    it 'includes the profile api key in the x-api-key request header' do
      create_school_student
      expect(WebMock).to have_requested(:post, create_students_url).with(headers: { 'x-api-key' => api_key })
    end

    it 'sets content-type of request to json' do
      create_school_student
      expect(WebMock).to have_requested(:post, create_students_url).with(headers: { 'content-type' => 'application/json' })
    end

    it 'sets accept header to json' do
      create_school_student
      expect(WebMock).to have_requested(:post, create_students_url).with(headers: { 'accept' => 'application/json' })
    end

    it 'sends the student details in the request body' do
      create_school_student
      expect(WebMock).to have_requested(:post, create_students_url).with(body: [{ name:, username:, password: }].to_json)
    end

    it 'returns the id of the created student(s) if successful' do
      response = { created: ['student-id'] }
      stub_request(:post, create_students_url)
        .to_return(status: 201, body: response.to_json, headers: { 'content-type' => 'application/json' })
      expect(create_school_student).to eq(response)
    end

    it 'raises 422 exception if 422 status code is returned' do
      response = { errors: [username: 'username', error: 'ERR_USER_EXISTS'] }
      stub_request(:post, create_students_url)
        .to_return(status: 422, body: response.to_json, headers: { 'content-type' => 'application/json' })

      expect { create_school_student }.to raise_error(ProfileApiClient::Student422Error)
        .with_message("Student not saved in Profile API (status code 422, username 'username', error 'username has already been taken')")
    end

    it 'raises exception if anything other that 201 status code is returned' do
      stub_request(:post, create_students_url)
        .to_return(status: 200)

      expect { create_school_student }.to raise_error(RuntimeError, 'Student not created in Profile API (status code 200)')
    end

    context 'when there are extraneous leading and trailing spaces in the student params' do
      let(:username) { '  username  ' }
      let(:password) { '  password  ' }
      let(:name) { '  name  ' }

      it 'strips the extraneous spaces' do
        create_school_student
        expect(WebMock).to have_requested(:post, create_students_url).with(body: [{ name: 'name', username: 'username', password: 'password' }].to_json)
      end
    end

    def create_school_student
      described_class.create_school_student(token:, username:, password:, name:, school_id: school.id)
    end
  end
end
