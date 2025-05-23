# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Destroy public project requests' do
  let(:locale) { 'fr' }
  let(:project_loader) { instance_double(ProjectLoader) }
  let(:project) { create(:project, locale: 'en') }
  let(:destroyer) { build(:user) }

  context 'when auth is correct' do
    let(:headers) { { Authorization: UserProfileMock::TOKEN } }

    before do
      allow(ProjectLoader).to receive(:new).and_return(project_loader)
      allow(project_loader).to receive(:load).and_return(project)
    end

    context 'when destroying project is successful' do
      before do
        authenticated_in_hydra_as(destroyer)

        allow(project).to receive(:destroy).and_return(true)
      end

      it 'builds ProjectLoader with identifier & locale' do
        delete("/api/public_projects/#{project.identifier}?locale=#{locale}", headers:)

        expect(ProjectLoader).to have_received(:new).with(project.identifier, [locale])
      end

      it 'uses ProjectLoader#load to find the project based on identifier & locale' do
        delete("/api/public_projects/#{project.identifier}?locale=#{locale}", headers:)

        expect(project_loader).to have_received(:load)
      end

      it 'returns success' do
        delete("/api/public_projects/#{project.identifier}", headers:)

        expect(response).to have_http_status(:success)
      end
    end

    context 'when destroying project fails' do
      before do
        authenticated_in_hydra_as(destroyer)

        allow(project).to receive(:destroy).and_return(false)
      end

      it 'returns error' do
        delete("/api/public_projects/#{project.identifier}", headers:)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  context 'when no token is given' do
    it 'returns unauthorized' do
      delete("/api/public_projects/#{project.identifier}")

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
