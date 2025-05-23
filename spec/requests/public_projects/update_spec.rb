# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Update public project requests' do
  let(:project) { create(:project) }
  let(:creator) { build(:user) }
  let(:params) { { project: { identifier: 'new-identifier', name: 'New name' } } }

  context 'when auth is correct' do
    let(:headers) { { Authorization: UserProfileMock::TOKEN } }

    context 'when updating project is successful' do
      before do
        authenticated_in_hydra_as(creator)

        response = OperationResponse.new
        response[:project] = project
        allow(PublicProject::Update).to receive(:call).and_return(response)
      end

      it 'returns success' do
        put("/api/public_projects/#{project.identifier}", headers:, params:)

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
        put("/api/public_projects/#{project.identifier}", headers:, params:)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  context 'when no token is given' do
    it 'returns unauthorized' do
      put("/api/public_projects/#{project.identifier}", headers:, params:)

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
