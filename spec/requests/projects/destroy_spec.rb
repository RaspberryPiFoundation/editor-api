# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project delete requests' do
  context 'when user is logged in' do
    let!(:project) { create(:project, user_id: user_id_by_index(0), locale: nil) }
    let(:headers) { { Authorization: UserProfileMock::TOKEN } }

    before do
      authenticate_as_school_owner
    end

    context 'when deleting a project the user owns' do
      it 'returns success' do
        delete("/api/projects/#{project.identifier}", headers:)

        expect(response).to have_http_status(:ok)
      end

      it "deletes user's project" do
        expect do
          delete "/api/projects/#{project.identifier}", headers:
        end.to change(Project, :count).by(-1)
      end
    end

    context 'when attempting to delete another users project' do
      let(:non_owned_project) { create(:project, locale: nil) }

      it 'returns forbidden' do
        delete("/api/projects/#{non_owned_project.identifier}", headers:)

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
