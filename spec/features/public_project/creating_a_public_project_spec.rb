# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a public project', type: :request do
  let(:creator) { build(:user) }
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:params) do
    {
      project: {
        identifier: 'test-project',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Test Project'
      }
    }
  end

  before do
    authenticated_in_hydra_as(creator)
  end

  it 'responds 201 Created' do
    post('/api/public_projects', headers:, params:)
    expect(response).to have_http_status(:created)
  end

  it 'responds with the project JSON' do
    post('/api/public_projects', headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data).to include(
      {
        identifier: 'test-project',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Test Project'
      }
    )
  end

  it 'responds 422 Unprocessable Entity when params are invalid' do
    post('/api/public_projects', headers:, params: { project: {} })
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'responds 401 Unauthorized when no token is given' do
    post('/api/public_projects', params:)
    expect(response).to have_http_status(:unauthorized)
  end
end
