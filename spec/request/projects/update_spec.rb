# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../app/lib/operation_response'

RSpec.describe 'Project update requests', type: :request do
  let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }
  let(:project) { create(:project, user_id: user_id) }

  context 'when authed user is project creator' do
    let(:project) { create(:project, :with_default_component, user_id: user_id) }
    let!(:component) { create(:component, project: project) }
    let(:default_component_params) do
      project.components.first.attributes.symbolize_keys.slice(
        :id,
        :name,
        :content,
        :extension,
        :index
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
      mock_oauth_user(user_id)
    end

    it 'returns success response' do
      put "/api/projects/#{project.identifier}", params: params
      expect(response.status).to eq(200)
    end

    it 'returns updated project json' do
      put "/api/projects/#{project.identifier}", params: params
      expect(response.body).to include('updated component content')
    end

    it 'calls update operation' do
      mock_response = instance_double(OperationResponse)
      allow(mock_response).to receive(:success?).and_return(true)
      allow(Project::Operation::Update).to receive(:call).and_return(mock_response)
      put "/api/projects/#{project.identifier}", params: params
      expect(Project::Operation::Update).to have_received(:call)
    end

    context 'when update is invalid' do
      let(:params) { { project: { components: [] } } }

      it 'returns error response' do
        put "/api/projects/#{project.identifier}", params: params
        expect(response.status).to eq(400)
      end
    end
  end

  context 'when authed user is not creator' do
    let(:project) { create(:project) }
    let(:params) { { project: { components: [] } } }

    before do
      mock_oauth_user(user_id)
    end

    it 'returns unauthorized response' do
      put "/api/projects/#{project.identifier}", params: params
      expect(response.status).to eq(401)
    end
  end

  context 'when auth is invalid' do
    it 'returns unauthorized' do
      put "/api/projects/#{project.identifier}"

      expect(response.status).to eq(401)
    end
  end
end
