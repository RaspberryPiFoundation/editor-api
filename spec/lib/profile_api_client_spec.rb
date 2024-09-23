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
    let(:error) { { 'message' => "Something's wrong with the password" } }

    it 'includes the message from the error' do
      expect(exception.message).to eq("Something's wrong with the password")
    end
  end

  describe ProfileApiClient::UnexpectedResponse do
    subject(:exception) { described_class.new(response) }

    let(:response) { instance_double(Faraday::Response, status:, headers:, body:) }
    let(:status) { 'response-status' }
    let(:headers) { 'response-headers' }
    let(:body) { 'response-body' }

    it 'includes expected and actual status code in the message' do
      expect(exception.message).to eq('Unexpected response from Profile API (status code response-status)')
    end

    it 'makes response status available' do
      expect(exception.response_status).to eq('response-status')
    end

    it 'makes response headers available' do
      expect(exception.response_headers).to eq('response-headers')
    end

    it 'makes response body available' do
      expect(exception.response_body).to eq('response-body')
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

      expect { create_school }.to raise_error(ProfileApiClient::UnexpectedResponse)
    end

    it 'raises faraday exception for 4xx and 5xx responses' do
      stub_request(:post, create_school_url)
        .to_return(status: 401)

      expect { create_school }.to raise_error(Faraday::Error)
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

    it 'raises exception if anything other than a 200 status code is returned' do
      stub_request(:get, list_safeguarding_flags_url)
        .to_return(status: 201)

      expect { list_safeguarding_flags }.to raise_error(ProfileApiClient::UnexpectedResponse)
    end

    it 'raises faraday exception for 4xx and 5xx responses' do
      stub_request(:get, list_safeguarding_flags_url)
        .to_return(status: 401)

      expect { list_safeguarding_flags }.to raise_error(Faraday::Error)
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
      expect(WebMock).to have_requested(:post, create_safeguarding_flag_url).with(body: { flag:, email: 'user@example.com' }.to_json)
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

      expect { create_safeguarding_flag }.to raise_error(ProfileApiClient::UnexpectedResponse)
    end

    it 'raises faraday exception for 4xx and 5xx responses' do
      stub_request(:post, create_safeguarding_flag_url)
        .to_return(status: 401)

      expect { create_safeguarding_flag }.to raise_error(Faraday::Error)
    end

    def create_safeguarding_flag
      described_class.create_safeguarding_flag(token:, flag:, email: 'user@example.com')
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

      expect { delete_safeguarding_flag }.to raise_error(ProfileApiClient::UnexpectedResponse)
    end

    it 'raises faraday exception for 4xx and 5xx responses' do
      stub_request(:delete, delete_safeguarding_flag_url)
        .to_return(status: 401)

      expect { delete_safeguarding_flag }.to raise_error(Faraday::Error)
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

    it 'raises 422 exception with the relevant message if 400 status code is returned' do
      response = { errors: [message: 'The password is well dodgy'] }
      stub_request(:post, create_students_url)
        .to_return(status: 400, body: response.to_json, headers: { 'content-type' => 'application/json' })

      expect { create_school_student }.to raise_error(ProfileApiClient::Student422Error)
        .with_message('The password is well dodgy')
    end

    it 'raises exception if anything other that 201 status code is returned' do
      stub_request(:post, create_students_url)
        .to_return(status: 200)

      expect { create_school_student }.to raise_error(ProfileApiClient::UnexpectedResponse)
    end

    it 'raises faraday exception for 4xx and 5xx responses' do
      stub_request(:post, create_students_url)
        .to_return(status: 401)

      expect { create_school_student }.to raise_error(Faraday::Error)
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

  describe '.list_school_student' do
    let(:school) { build(:school, id: SecureRandom.uuid) }
    let(:list_students_url) { "#{api_url}/api/v1/schools/#{school.id}/students/list" }
    let(:student_ids) { [SecureRandom.uuid] }

    before do
      stub_request(:post, list_students_url).to_return(status: 200, body: '[]', headers: { 'content-type' => 'application/json' })
    end

    it 'makes a request to the profile api host' do
      list_school_students
      expect(WebMock).to have_requested(:post, list_students_url)
    end

    it 'includes token in the authorization request header' do
      list_school_students
      expect(WebMock).to have_requested(:post, list_students_url).with(headers: { authorization: "Bearer #{token}" })
    end

    it 'includes the profile api key in the x-api-key request header' do
      list_school_students
      expect(WebMock).to have_requested(:post, list_students_url).with(headers: { 'x-api-key' => api_key })
    end

    it 'sets content-type of request to json' do
      list_school_students
      expect(WebMock).to have_requested(:post, list_students_url).with(headers: { 'content-type' => 'application/json' })
    end

    it 'sets accept header to json' do
      list_school_students
      expect(WebMock).to have_requested(:post, list_students_url).with(headers: { 'accept' => 'application/json' })
    end

    it 'sets body to the student IDs' do
      list_school_students
      expect(WebMock).to have_requested(:post, list_students_url).with(body: student_ids)
    end

    it 'returns the student(s) if successful' do
      student = {
        id: '549e4674-6ffd-4ac6-9a97-b4d7e5c0e5c5',
        schoolId: '132383f1-702a-46a0-9eb2-a40dd4f212e3',
        name: 'student-name',
        username: 'student-username',
        createdAt: '2024-07-03T13:00:40.041Z',
        updatedAt: '2024-07-03T13:00:40.041Z',
        discardedAt: nil
      }
      expected = ProfileApiClient::Student.new(**student)
      stub_request(:post, list_students_url)
        .to_return(status: 200, body: [student].to_json, headers: { 'content-type' => 'application/json' })
      expect(list_school_students).to eq([expected])
    end

    it 'raises exception if anything other that 200 status code is returned' do
      stub_request(:post, list_students_url)
        .to_return(status: 201)

      expect { list_school_students }.to raise_error(ProfileApiClient::UnexpectedResponse)
    end

    it 'raises faraday exception for 4xx and 5xx responses' do
      stub_request(:post, list_students_url)
        .to_return(status: 401)

      expect { list_school_students }.to raise_error(Faraday::Error)
    end

    def list_school_students
      described_class.list_school_students(token:, school_id: school.id, student_ids:)
    end
  end

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe '.update_school_student' do
    let(:username) { 'username' }
    let(:password) { 'password' }
    let(:name) { 'name' }
    let(:school) { build(:school, id: SecureRandom.uuid) }
    let(:student) { create(:student, school:) }
    let(:update_student_url) { "#{api_url}/api/v1/schools/#{school.id}/students/#{student.id}" }

    before do
      stub_request(:patch, update_student_url)
        .to_return(
          status: 200,
          body: '{"id":"","schoolId":"","name":"","username":"","createdAt":"","updatedAt":"","discardedAt":""}',
          headers: { 'content-type' => 'application/json' }
        )
    end

    it 'makes a request to the profile api host' do
      update_school_student
      expect(WebMock).to have_requested(:patch, update_student_url)
    end

    it 'includes token in the authorization request header' do
      update_school_student
      expect(WebMock).to have_requested(:patch, update_student_url).with(headers: { authorization: "Bearer #{token}" })
    end

    it 'includes the profile api key in the x-api-key request header' do
      update_school_student
      expect(WebMock).to have_requested(:patch, update_student_url).with(headers: { 'x-api-key' => api_key })
    end

    it 'sets content-type of request to json' do
      update_school_student
      expect(WebMock).to have_requested(:patch, update_student_url).with(headers: { 'content-type' => 'application/json' })
    end

    it 'sets accept header to json' do
      update_school_student
      expect(WebMock).to have_requested(:patch, update_student_url).with(headers: { 'accept' => 'application/json' })
    end

    it 'sends the student details in the request body' do
      update_school_student
      expect(WebMock).to have_requested(:patch, update_student_url).with(body: { name:, username:, password: }.to_json)
    end

    it 'returns the updated student if successful' do
      response = { id: 'id', schoolId: 'school-id', name: 'new-name', username: 'new-username', createdAt: '', updatedAt: '', discardedAt: '' }
      expected = ProfileApiClient::Student.new(**response)
      stub_request(:patch, update_student_url)
        .to_return(status: 200, body: response.to_json, headers: { 'content-type' => 'application/json' })
      expect(update_school_student).to eq(expected)
    end

    it 'raises 422 exception with the relevant message if 400 status code is returned' do
      response = { errors: [message: 'The username is well dodgy'] }
      stub_request(:patch, update_student_url)
        .to_return(status: 400, body: response.to_json, headers: { 'content-type' => 'application/json' })

      expect { update_school_student }.to raise_error(ProfileApiClient::Student422Error)
        .with_message('The username is well dodgy')
    end

    it 'raises exception if anything other that 200 status code is returned' do
      stub_request(:patch, update_student_url)
        .to_return(status: 201)

      expect { update_school_student }.to raise_error(ProfileApiClient::UnexpectedResponse)
    end

    it 'raises faraday exception for 4xx and 5xx responses' do
      stub_request(:patch, update_student_url)
        .to_return(status: 401)

      expect { update_school_student }.to raise_error(Faraday::Error)
    end

    context 'when there are extraneous leading and trailing spaces in the student params' do
      let(:username) { '  username  ' }
      let(:password) { '  password  ' }
      let(:name) { '  name  ' }

      it 'strips the extraneous spaces' do
        update_school_student
        expect(WebMock).to have_requested(:patch, update_student_url).with(body: { name: 'name', username: 'username', password: 'password' }.to_json)
      end
    end

    context 'when optional values are nil' do
      let(:username) { nil }
      let(:password) { nil }
      let(:name) { nil }

      it 'does not send empty values' do
        update_school_student
        expect(WebMock).to have_requested(:patch, update_student_url).with(body: {}.to_json)
      end
    end

    def update_school_student
      described_class.update_school_student(token:, username:, password:, name:, school_id: school.id, student_id: student.id)
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  describe '.school_student' do
    let(:school) { build(:school, id: SecureRandom.uuid) }
    let(:student_url) { "#{api_url}/api/v1/schools/#{school.id}/students/#{student_id}" }
    let(:student_id) { SecureRandom.uuid }

    before do
      stub_request(:get, student_url)
        .to_return(
          status: 200,
          body: '{"id":"","schoolId":"","name":"","username":"","createdAt":"","updatedAt":"","discardedAt":""}',
          headers: { 'content-type' => 'application/json' }
        )
    end

    it 'makes a request to the profile api host' do
      school_student
      expect(WebMock).to have_requested(:get, student_url)
    end

    it 'includes token in the authorization request header' do
      school_student
      expect(WebMock).to have_requested(:get, student_url).with(headers: { authorization: "Bearer #{token}" })
    end

    it 'includes the profile api key in the x-api-key request header' do
      school_student
      expect(WebMock).to have_requested(:get, student_url).with(headers: { 'x-api-key' => api_key })
    end

    it 'sets accept header to json' do
      school_student
      expect(WebMock).to have_requested(:get, student_url).with(headers: { 'accept' => 'application/json' })
    end

    it 'returns the student(s) if successful' do
      student = {
        id: '549e4674-6ffd-4ac6-9a97-b4d7e5c0e5c5',
        schoolId: '132383f1-702a-46a0-9eb2-a40dd4f212e3',
        name: 'student-name',
        username: 'student-username',
        createdAt: '2024-07-03T13:00:40.041Z',
        updatedAt: '2024-07-03T13:00:40.041Z',
        discardedAt: nil
      }
      expected = ProfileApiClient::Student.new(**student)
      stub_request(:get, student_url)
        .to_return(status: 200, body: student.to_json, headers: { 'content-type' => 'application/json' })
      expect(school_student).to eq(expected)
    end

    it 'raises exception if anything other than a 200 status code is returned' do
      stub_request(:get, student_url)
        .to_return(status: 201)

      expect { school_student }.to raise_error(ProfileApiClient::UnexpectedResponse)
    end

    it 'raises faraday exception for 4xx and 5xx responses' do
      stub_request(:get, student_url)
        .to_return(status: 401)

      expect { school_student }.to raise_error(Faraday::Error)
    end

    private

    def school_student
      described_class.school_student(token:, school_id: school.id, student_id:)
    end
  end

  describe '.delete_school_student' do
    let(:school) { build(:school, id: SecureRandom.uuid) }
    let(:delete_student_url) { "#{api_url}/api/v1/schools/#{school.id}/students/#{student_id}" }
    let(:student_id) { SecureRandom.uuid }

    before do
      stub_request(:delete, delete_student_url).to_return(status: 204, body: '', headers: { 'content-type' => 'application/json' })
    end

    it 'makes a request to the profile api host' do
      delete_school_student
      expect(WebMock).to have_requested(:delete, delete_student_url)
    end

    it 'includes token in the authorization request header' do
      delete_school_student
      expect(WebMock).to have_requested(:delete, delete_student_url).with(headers: { authorization: "Bearer #{token}" })
    end

    it 'includes the profile api key in the x-api-key request header' do
      delete_school_student
      expect(WebMock).to have_requested(:delete, delete_student_url).with(headers: { 'x-api-key' => api_key })
    end

    it 'sets accept header to json' do
      delete_school_student
      expect(WebMock).to have_requested(:delete, delete_student_url).with(headers: { 'accept' => 'application/json' })
    end

    it 'returns nil if successful' do
      stub_request(:delete, delete_student_url)
        .to_return(status: 204, body: '', headers: { 'content-type' => 'application/json' })
      expect(delete_school_student).to be_nil
    end

    it 'raises exception if anything other than a 200 status code is returned' do
      stub_request(:delete, delete_student_url)
        .to_return(status: 201)

      expect { delete_school_student }.to raise_error(ProfileApiClient::UnexpectedResponse)
    end

    it 'raises faraday exception for 4xx and 5xx responses' do
      stub_request(:delete, delete_student_url)
        .to_return(status: 401)

      expect { delete_school_student }.to raise_error(Faraday::Error)
    end

    private

    def delete_school_student
      described_class.delete_school_student(token:, school_id: school.id, student_id:)
    end
  end
end
