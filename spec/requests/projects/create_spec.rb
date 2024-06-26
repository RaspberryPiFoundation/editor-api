# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create project requests' do
  let(:project) { create(:project, user_id: authenticated_user.id) }
  let(:school) { create(:school) }
  let(:owner) { create(:owner, school:) }

  context 'when auth is correct' do
    let(:headers) { { Authorization: UserProfileMock::TOKEN } }

    context 'when creating project is successful' do
      before do
        authenticated_in_hydra_as(owner)

        response = OperationResponse.new
        response[:project] = project
        allow(Project::Create).to receive(:call).and_return(response)
      end

      it 'returns success' do
        post('/api/projects', headers:)

        expect(response).to have_http_status(:created)
      end
    end

    context 'when creating project fails' do
      before do
        authenticated_in_hydra_as(owner)

        response = OperationResponse.new
        response[:error] = 'Error creating project'
        allow(Project::Create).to receive(:call).and_return(response)
      end

      it 'returns error' do
        post('/api/projects', headers:)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  context 'when no token is given' do
    it 'returns unauthorized' do
      post '/api/projects'

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
