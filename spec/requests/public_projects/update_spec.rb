# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update public project requests' do
  let(:locale) { 'fr' }
  let(:project_loader) { instance_double(ProjectLoader) }
  let(:project) { create(:project, locale: 'en', project_type: Project::Types::SCRATCH) }
  let(:creator) { build(:experience_cs_admin_user) }
  let(:params) { { project: { identifier: 'new-identifier', name: 'New name' } } }

  context 'when auth is correct' do
    let(:headers) { { Authorization: UserProfileMock::TOKEN } }

    context 'when updating project is successful' do
      before do
        authenticated_in_hydra_as(creator)

        allow(ProjectLoader).to receive(:new).and_return(project_loader)
        allow(project_loader).to receive(:load).and_return(project)

        response = OperationResponse.new
        response[:project] = project
        allow(PublicProject::Update).to receive(:call).and_return(response)
      end

      it 'builds ProjectLoader with identifier & locale' do
        put("/api/public_projects/#{project.identifier}?project_type=scratch&locale=#{locale}", headers:, params:)

        expect(ProjectLoader).to have_received(:new).with(project.identifier, [locale])
      end

      it 'uses ProjectLoader#load to find the project based on identifier & locale' do
        put("/api/public_projects/#{project.identifier}?project_type=scratch&locale=#{locale}", headers:, params:)

        expect(project_loader).to have_received(:load)
      end

      it 'returns success' do
        put("/api/public_projects/#{project.identifier}?project_type=scratch", headers:, params:)

        expect(response).to have_http_status(:success)
      end
    end

    context 'when updating project fails' do
      before do
        authenticated_in_hydra_as(creator)

        response = OperationResponse.new
        response[:error] = 'Error updating project'
        allow(PublicProject::Update).to receive(:call).and_return(response)
      end

      it 'returns error' do
        put("/api/public_projects/#{project.identifier}?project_type=scratch", headers:, params:)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  context 'when no token is given' do
    it 'returns unauthorized' do
      put("/api/public_projects/#{project.identifier}?project_type=scratch", headers:, params:)

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
