# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project show requests' do
  let!(:project) { create(:project, locale: nil) }
  let(:project_json) do
    {
      identifier: project.identifier,
      project_type: 'python',
      locale: project.locale,
      name: project.name,
      user_id: project.user_id,
      components: [],
      image_list: []
    }.to_json
  end
  let(:headers) { {} }

  context 'when user is logged in' do
    let(:headers) { { Authorization: 'dummy-token' } }

    before do
      stub_fetch_oauth_user_id(project.user_id)
    end

    context 'when loading own project' do
      it 'returns success response' do
        get("/api/projects/#{project.identifier}", headers:)

        expect(response).to have_http_status(:ok)
      end

      it 'returns json' do
        get("/api/projects/#{project.identifier}", headers:)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end

      it 'returns the project json' do
        get("/api/projects/#{project.identifier}", headers:)
        expect(response.body).to eq(project_json)
      end
    end

    context 'when loading another user\'s project' do
      let!(:another_project) { create(:project, locale: nil) }
      let(:another_project_json) do
        {
          identifier: another_project.identifier,
          project_type: 'python',
          name: another_project.name,
          locale: another_project.locale,
          user_id: another_project.user_id,
          components: [],
          image_list: []
        }.to_json
      end

      it 'returns forbidden response' do
        get("/api/projects/#{another_project.identifier}", headers:)

        expect(response).to have_http_status(:forbidden)
      end

      it 'does not return the project json' do
        get("/api/projects/#{another_project.identifier}", headers:)
        expect(response.body).not_to include(another_project_json)
      end
    end
  end

  context 'when user is not logged in' do
    context 'when loading a starter project' do
      let!(:starter_project) { create(:project, user_id: nil, locale: 'ja-JP') }
      let(:starter_project_json) do
        {
          identifier: starter_project.identifier,
          project_type: 'python',
          locale: starter_project.locale,
          name: starter_project.name,
          user_id: starter_project.user_id,
          components: [],
          image_list: []
        }.to_json
      end

      it 'returns success response' do
        get("/api/projects/#{starter_project.identifier}?locale=#{starter_project.locale}", headers:)
        expect(response).to have_http_status(:ok)
      end

      it 'returns json' do
        get("/api/projects/#{starter_project.identifier}?locale=#{starter_project.locale}", headers:)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end

      it 'returns the project json' do
        get("/api/projects/#{starter_project.identifier}?locale=#{starter_project.locale}", headers:)
        expect(response.body).to eq(starter_project_json)
      end

      it 'returns 404 response if invalid project' do
        get('/api/projects/no-such-project', headers:)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when loading an owned project' do
      it 'returns forbidden response' do
        get("/api/projects/#{project.identifier}", headers:)

        expect(response).to have_http_status(:forbidden)
      end

      it 'does not return the project json' do
        get("/api/projects/#{project.identifier}", headers:)
        expect(response.body).not_to include(project_json)
      end
    end
  end
end
