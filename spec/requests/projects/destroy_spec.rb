# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project delete requests' do
  context 'when user is logged in' do
    let!(:project) { create(:project, user_id: owner.id, locale: nil) }
    let(:headers) { { Authorization: UserProfileMock::TOKEN } }
    let(:owner) { create(:owner, school:) }
    let(:school) { create(:school) }

    before do
      authenticated_in_hydra_as(owner)
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

    context 'when an Experience CS admin destroys a starter Scratch project' do
      let(:project) do
        create(
          :project, {
            project_type: Project::Types::SCRATCH,
            user_id: nil,
            locale: 'en'
          }
        )
      end
      let(:experience_cs_admin) { create(:experience_cs_admin_user) }

      before do
        authenticated_in_hydra_as(experience_cs_admin)
      end

      it 'deletes the project' do
        expect do
          delete("/api/projects/#{project.identifier}", headers:)
        end.to change(Project, :count).by(-1)
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
