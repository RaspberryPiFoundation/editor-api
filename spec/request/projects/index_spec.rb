# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project index requests', type: :request do
  let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }
  let!(:projects) { create_list(:project, 2, user_id: user_id) }
  let!(:other_projects) { create_list(:project, 2) }

  context 'when user is logged in' do
    before do
      mock_oauth_user(user_id)
    end

    it 'returns success response' do
      get "/api/projects"
      expect(response.status).to eq(200)
    end

    it 'returns users projects' do
      expected_json = projects.map do |p|
        {
          identifier: p.identifier,
          project_type: p.project_type,
          name: p.name,
          user_id: p.user_id
        }
      end.to_json

      get "/api/projects"
      expect(response.body).to eq(expected_json)
    end
  end

  context 'when no user' do
    it 'returns unauthorized' do
      get "/api/projects"
      expect(response.status).to eq(401)
    end
  end
end
