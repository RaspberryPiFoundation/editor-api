# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project delete requests', type: :request do
  let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }

  context 'when user is logged in' do
    let!(:project) { create(:project, user_id: user_id) }

    before do
      mock_oauth_user(user_id)
    end

    context 'when deleting a project the user owns' do
      it 'returns success' do
        delete "/api/projects/#{project.identifier}"
        expect(response.status).to eq(200)
      end

      it "deletes user's project" do
        expect do
          delete "/api/projects/#{project.identifier}"
        end.to change(Project, :count).by(-1)
      end
    end

    context 'when attempting to delete another users project' do
      let(:non_owned_project) { create(:project) }

      it 'returns forbidden' do
        delete "/api/projects/#{non_owned_project.identifier}"
        expect(response.status).to eq(403)
      end
    end
  end

  context 'when no user' do
    it 'returns unauthorized' do
      delete '/api/projects/project-identifier'
      expect(response.status).to eq(401)
    end
  end
end
