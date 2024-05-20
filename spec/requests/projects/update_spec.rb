# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project update requests' do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }

  context 'when authed user is project creator' do
    let(:project) { create(:project, :with_default_component, user_id: User::OWNER_ID, locale: nil) }
    let!(:component) { create(:component, project:) }
    let(:default_component_params) do
      project.components.first.attributes.symbolize_keys.slice(
        :id,
        :name,
        :content,
        :extension
      )
    end

    let(:params) do
      { project:
        { components: [
          default_component_params,
          { id: component.id, name: 'updated', extension: 'py', content: 'updated component content' }
        ] } }
    end

    before do
      authenticate_as_school_owner
    end

    it 'returns success response' do
      put("/api/projects/#{project.identifier}", params:, headers:)
      expect(response).to have_http_status(:ok)
    end

    it 'returns updated project json' do
      put("/api/projects/#{project.identifier}", params:, headers:)
      expect(response.body).to include('updated component content')
    end

    it 'calls update operation' do
      mock_response = instance_double(OperationResponse)
      allow(mock_response).to receive(:success?).and_return(true)
      allow(Project::Update).to receive(:call).and_return(mock_response)
      put("/api/projects/#{project.identifier}", params:, headers:)
      expect(Project::Update).to have_received(:call)
    end

    context 'when no components specified' do
      let(:params) { { project: { name: 'updated project name' } } }

      it 'returns success response' do
        put("/api/projects/#{project.identifier}", params:, headers:)
        expect(response).to have_http_status(:ok)
      end

      it 'returns json with updated project properties' do
        put("/api/projects/#{project.identifier}", params:, headers:)
        expect(response.body).to include('updated project name')
      end

      it 'returns json with previous project components' do
        put("/api/projects/#{project.identifier}", params:, headers:)
        expect(response.body).to include(project.components.first.attributes[:content].to_s)
      end
    end

    context 'when update is invalid' do
      let(:params) { { project: { components: [] } } }

      it 'returns error response' do
        put("/api/projects/#{project.identifier}", params:, headers:)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  context 'when authed user is not creator' do
    let(:project) { create(:project, locale: nil) }
    let(:params) { { project: { components: [] } } }

    before do
      authenticate_as_school_owner
    end

    it 'returns forbidden response' do
      put("/api/projects/#{project.identifier}", params:, headers:)
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'when auth token is invalid' do
    let(:project) { create(:project) }

    before do
      unauthenticated_user
    end

    it 'returns unauthorized' do
      put("/api/projects/#{project.identifier}", headers:)

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
