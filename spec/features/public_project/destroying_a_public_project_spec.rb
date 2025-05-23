# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Destroying a public project', type: :request do
  let(:destroyer) { build(:experience_cs_admin_user) }
  let(:project) { create(:project, locale: 'en', project_type: Project::Types::SCRATCH) }
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }

  before do
    authenticated_in_hydra_as(destroyer)
  end

  it 'responds 200 OK' do
    delete("/api/public_projects/#{project.identifier}?project_type=scratch", headers:)
    expect(response).to have_http_status(:success)
  end

  it 'deletes the project' do
    delete("/api/public_projects/#{project.identifier}?project_type=scratch", headers:)
    expect(Project).not_to exist(identifier: project.identifier)
  end

  it 'responds 401 Unauthorized when no token is given' do
    delete("/api/public_projects/#{project.identifier}?project_type=scratch")
    expect(response).to have_http_status(:unauthorized)
  end

  context 'when destroyer is not an experience-cs admin' do
    let(:destroyer) { build(:user) }

    it 'responds 403 Forbidden' do
      delete("/api/public_projects/#{project.identifier}?project_type=scratch", headers:)
      expect(response).to have_http_status(:forbidden)
    end
  end

  it 'responds 404 Not Found when project is not found' do
    delete('/api/public_projects/another-identifier?project_type=scratch', headers:)
    expect(response).to have_http_status(:not_found)
  end
end
