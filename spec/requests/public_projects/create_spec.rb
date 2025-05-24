# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create public project requests' do
  let(:project) { create(:project) }
  let(:creator) { build(:experience_cs_admin_user) }
  let(:params) { { project: { project_type: Project::Types::SCRATCH } } }

  context 'when auth is correct' do
    let(:headers) { { Authorization: UserProfileMock::TOKEN } }

    context 'when creating project is successful' do
      before do
        authenticated_in_hydra_as(creator)

        response = OperationResponse.new
        response[:project] = project
        allow(PublicProject::Create).to receive(:call).and_return(response)
      end

      it 'returns success' do
        post('/api/public_projects', headers:, params:)

        expect(response).to have_http_status(:created)
      end
    end

    context 'when creating project fails' do
      before do
        authenticated_in_hydra_as(creator)

        response = OperationResponse.new
        response[:error] = 'Error creating project'
        allow(PublicProject::Create).to receive(:call).and_return(response)
      end

      it 'returns error' do
        post('/api/public_projects', headers:, params:)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  context 'when no token is given' do
    it 'returns unauthorized' do
      post('/api/public_projects', params:)

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
