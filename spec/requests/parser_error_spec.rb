# frozen_string_literal: true

require 'rails_helper'

describe 'APIController malformed JSON error handling', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:) }
  let(:json_headers) do
    {
      'CONTENT_TYPE' => 'application/json',
      'ACCEPT' => 'application/json'
    }
  end

  before do
    authenticated_in_hydra_as(teacher)
  end

  it 'returns a JSON error message and 400 status for malformed JSON' do
    malformed_json = '{ "school": { "name": "A new school" }, }'
    post '/api/schools', params: malformed_json, headers: headers.merge(json_headers)
    expect(response.status).to eq(400)
    expect(response.content_type).to include('application/json')
    expect(JSON.parse(response.body)['error']).to eq('Malformed JSON or invalid request body.')
  end
end
