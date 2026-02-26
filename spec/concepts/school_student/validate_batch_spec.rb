# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolStudent::ValidateBatch do
  let(:school) { create(:verified_school) }
  let(:token) { UserProfileMock::TOKEN }

  context 'when all students are valid' do
    let(:valid_students) do
      [
        {
          username: 'student1',
          password: 'SaoXlDBAyiAFoMH3VsddhdA7JWnM8P8by1wOjBUWH2g=',
          name: 'Student One'
        },
        {
          username: 'student2',
          password: 'SaoXlDBAyiAFoMH3VsddhdA7JWnM8P8by1wOjBUWH2g=',
          name: 'Student Two'
        }
      ]
    end

    before do
      allow(ProfileApiClient).to receive(:validate_school_students).and_return(OperationResponse.new)
    end

    it 'does not raise an error' do
      expect do
        described_class.call(school: school, students: valid_students, token: token)
      end.not_to raise_error
    end

    it 'returns a successful operation response' do
      result = described_class.call(school: school, students: valid_students, token: token)
      expect(result).to be_success
    end

    it 'does not include any errors in the response' do
      result = described_class.call(school: school, students: valid_students, token: token)
      expect(result[:error]).to be_nil
      expect(result[:error_type]).to be_nil
    end
  end

  context 'when some students are invalid' do
    let(:invalid_students) do
      [
        {
          username: 'johndoe',
          password: 'SaoXlDBAyiAFoMH3VsddhdA7JWnM8P8by1wOjBUWH2g=',
          name: 'John Doe'
        },
        {
          username: 'janedoe',
          password: 'SaoXlDBAyiAFoMH3VsddhdA7JWnM8P8by1wOjBUWH2g=',
          name: 'jane doe'
        }
      ]
    end

    let(:expected_errors) do
      {
        'johndoe' => ['doesNotEqualUsername'],
        'janedoe' => ['isRequired']
      }
    end

    let(:error_response) do
      ProfileApiClient::Student422Error.new([{
                                              'username' => 'johndoe',
                                              'errorCode' => 'doesNotEqualUsername',
                                              'message' => 'Password canot match username',
                                              'location' => 'body'
                                            },
                                             {
                                               'username' => 'janedoe',
                                               'errorCode' => 'isRequired',
                                               'message' => 'Username is required',
                                               'location' => 'body'
                                             }])
    end

    before do
      allow(ProfileApiClient).to receive(:validate_school_students).and_raise(error_response)
    end

    it 'does not raise an error' do
      expect do
        described_class.call(school: school, students: invalid_students, token: token)
      end.not_to raise_error
    end

    it 'returns an operation response without success' do
      result = described_class.call(school: school, students: invalid_students, token: token)
      expect(result).to be_failure
    end

    it 'returns an error type of :validation_error' do
      result = described_class.call(school: school, students: invalid_students, token: token)
      expect(result[:error_type]).to eq(:validation_error)
    end

    it 'includes the validation errors in the response' do
      result = described_class.call(school: school, students: invalid_students, token: token)
      expect(result[:error]).to be_present
      expect(result[:error]).to eq(expected_errors)
    end
  end

  context 'when passwords are not encrypted' do
    let(:unencrypted_students) do
      [
        {
          username: 'student1',
          password: 'PlainTextPassword',
          name: 'Student One'
        }
      ]
    end

    it 'does not raise an error' do
      expect do
        described_class.call(school: school, students: unencrypted_students, token: token)
      end.not_to raise_error
    end

    it 'returns an operation response without success' do
      result = described_class.call(school: school, students: unencrypted_students, token: token)
      expect(result).to be_failure
    end

    it 'returns an error type of :standard_error' do
      result = described_class.call(school: school, students: unencrypted_students, token: token)
      expect(result[:error_type]).to eq(:standard_error)
    end

    it 'includes a suitable error message in the response' do
      result = described_class.call(school: school, students: unencrypted_students, token: token)
      expect(result[:error]).to include('Decryption failed')
    end
  end
end
