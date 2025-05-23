# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Updating a public project', type: :request do
  let(:creator) { build(:experience_cs_admin_user) }
  let(:user_id) { nil }
  let(:project) { create(:project, locale: 'en', project_type: Project::Types::SCRATCH, user_id:) }
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:params) { { project: { identifier: 'new-identifier', name: 'New name' } } }

  before do
    authenticated_in_hydra_as(creator)
  end

  it 'responds 200 OK' do
    put("/api/public_projects/#{project.identifier}?project_type=scratch", headers:, params:)
    expect(response).to have_http_status(:success)
  end

  it 'responds with the project JSON' do
    put("/api/public_projects/#{project.identifier}?project_type=scratch", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data).to include(identifier: 'new-identifier', name: 'New name')
  end

  it 'does not change locale on project even if one is supplied' do
    locale = 'fr'

    put("/api/public_projects/#{project.identifier}?project_type=scratch", headers:, params: params.merge(locale:))
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data).to include(locale: 'en')
  end

  it 'does not change project_type on project even if one is supplied' do
    project_type = Project::Types::PYTHON

    put("/api/public_projects/#{project.identifier}?project_type=scratch", headers:, params: params.merge(project_type:))
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data).to include(project_type: Project::Types::SCRATCH)
  end

  it 'does not set user_id on project even if one is supplied' do
    user_id = SecureRandom.uuid

    put("/api/public_projects/#{project.identifier}?project_type=scratch", headers:, params: params.merge(user_id:))
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data).to include(user_id: nil)
  end

  context 'when creator is not an experience-cs admin' do
    let(:creator) { build(:user) }

    it 'responds 403 Forbidden' do
      put("/api/public_projects/#{project.identifier}?project_type=scratch", headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end
  end

  it 'responds 400 Bad Request when params are malformed' do
    put("/api/public_projects/#{project.identifier}?project_type=scratch", headers:, params: {})
    expect(response).to have_http_status(:bad_request)
  end

  it 'responds 401 Unauthorized when no token is given' do
    put("/api/public_projects/#{project.identifier}?project_type=scratch", params:)
    expect(response).to have_http_status(:unauthorized)
  end

  context 'when project is not public' do
    let(:user_id) { SecureRandom.uuid }

    it 'responds 403 Forbidden' do
      put("/api/public_projects/#{project.identifier}?project_type=scratch", headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end
  end

  it 'responds 404 Not Found when project is not found' do
    put('/api/public_projects/another-identifier?project_type=scratch', headers:, params:)
    expect(response).to have_http_status(:not_found)
  end
end
