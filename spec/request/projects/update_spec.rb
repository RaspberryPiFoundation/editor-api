# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project update requests', type: :request do
  let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }
  let(:project) { create(:project, user_id: user_id) }

  context 'when authed user is project creator' do
    let(:project) { create(:project, user_id: user_id) }
    let!(:component) { create(:component, project: project) }
    let(:changes) { { name: 'updated', extension: 'py', content: 'updated content' } }
    let(:params) { { project: { components: [{ id: component.id, **changes }] } } }

    before do
      mock_oauth_user(user_id)
    end

    it 'returns success response' do
      put "/api/projects/#{project.identifier}", params: params
      expect(response.status).to eq(200)
    end

    it 'updates component' do
      put "/api/projects/#{project.identifier}", params: params
      updated = component.reload.attributes.symbolize_keys.slice(:name, :content, :extension)
      expect(updated).to eq(changes)
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
