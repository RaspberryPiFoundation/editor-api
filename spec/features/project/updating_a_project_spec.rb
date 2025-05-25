# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Updating a project', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:locale) { 'en' }
  let!(:project) { create(:project, name: 'Test Project', user_id: owner.id, locale:) }
  let(:owner) { create(:owner, school:) }
  let(:school) { create(:school) }

  let(:params) do
    {
      project: {
        name: 'New Name',
        components: [
          { name: 'main', extension: 'py', content: 'print("hello")' }
        ]
      }
    }
  end

  before do
    authenticated_in_hydra_as(owner)

    create(:component, project:, name: 'main', extension: 'py', content: 'print("hi")')
  end

  it 'responds 200 OK' do
    put("/api/projects/#{project.identifier}", headers:, params:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the project JSON' do
    put("/api/projects/#{project.identifier}", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:name]).to eq('New Name')
  end

  it 'responds with the components JSON' do
    put("/api/projects/#{project.identifier}", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:components].first[:content]).to eq('print("hello")')
  end

  it 'responds 422 Unprocessable Entity when params are invalid' do
    put("/api/projects/#{project.identifier}", headers:, params: { project: { components: [{ name: ' ' }] } })
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'responds 401 Unauthorized when no token is given' do
    put("/api/projects/#{project.identifier}", params:)
    expect(response).to have_http_status(:unauthorized)
  end

  context 'when locale is nil, i.e. the other fallback locale in ProjectLoader' do
    let(:locale) { nil }

    it 'responds 200 OK even though no locale is specified in query string' do
      put("/api/projects/#{project.identifier}", headers:, params:)
      expect(response).to have_http_status(:ok)
    end
  end

  context "when locale is 'fr', i.e. not a fallback locale in ProjectLoader" do
    let(:locale) { 'fr' }

    it 'responds 200 OK if locale is specified in query string' do
      put("/api/projects/#{project.identifier}?locale=fr", headers:, params:)
      expect(response).to have_http_status(:ok)
    end

    it 'responds 404 Not Found if locale is not specified in query string' do
      put("/api/projects/#{project.identifier}", headers:, params:)
      expect(response).to have_http_status(:not_found)
    end
  end
end
