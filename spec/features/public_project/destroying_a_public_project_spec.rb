# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Destroying a public project', type: :request do
  let(:destroyer) { build(:user) }
  let(:project) { create(:project, locale: 'en') }
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }

  before do
    authenticated_in_hydra_as(destroyer)
  end

  it 'responds 200 OK' do
    delete("/api/public_projects/#{project.identifier}", headers:)
    expect(response).to have_http_status(:success)
  end

  it 'deletes the project' do
    delete("/api/public_projects/#{project.identifier}", headers:)
    expect(Project).not_to exist(identifier: project.identifier)
  end

  it 'responds 401 Unauthorized when no token is given' do
    delete("/api/public_projects/#{project.identifier}")
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 404 Not Found when project is not found' do
    delete('/api/public_projects/another-identifier', headers:)
    expect(response).to have_http_status(:not_found)
  end
end
