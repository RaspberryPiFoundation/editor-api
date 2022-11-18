# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project show requests', type: :request do
  let!(:project) { create(:project) }
  let(:expected_json) do
    {
      identifier: project.identifier,
      project_type: 'python',
      name: project.name,
      user_id: project.user_id,
      components: [],
      image_list: []
    }.to_json
  end

  it 'returns success response' do
    get "/api/projects/#{project.identifier}"

    expect(response).to have_http_status(:ok)
  end

  it 'returns json' do
    get "/api/projects/#{project.identifier}"
    expect(response.content_type).to eq('application/json; charset=utf-8')
  end

  it 'returns the project json' do
    get "/api/projects/#{project.identifier}"
    expect(response.body).to eq(expected_json)
  end

  it 'returns 404 response if invalid project' do
    get '/api/projects/no-such-project'

    expect(response).to have_http_status(:not_found)
  end
end
