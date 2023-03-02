# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project delete requests' do
  let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }

  context 'when user is logged in' do
    let!(:project) { create(:project, user_id:) }
    let(:headers) { { Authorization: 'dummy-token' } }

    before do
      stub_fetch_oauth_user_id(user_id)
    end

    context 'when deleting a project the user owns' do
      it 'returns success' do
        delete "/api/projects/#{project.identifier}", headers: headers

        expect(response).to have_http_status(:ok)
      end

      it "deletes user's project" do
        expect do
          delete "/api/projects/#{project.identifier}", headers:
        end.to change(Project, :count).by(-1)
      end
    end

    context 'when attempting to delete another users project' do
      let(:non_owned_project) { create(:project) }

      it 'returns forbidden' do
        delete "/api/projects/#{non_owned_project.identifier}", headers: headers

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context 'when no token is given' do
    it 'returns unauthorized' do
      delete '/api/projects/project-identifier'

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
