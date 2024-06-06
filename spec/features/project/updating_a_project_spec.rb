# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Updating a project', type: :request do
  before do
    authenticate_as_school_owner(owner)

    create(:component, project:, name: 'main', extension: 'py', content: 'print("hi")')
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:project) { create(:project, name: 'Test Project', user_id: owner.id) }
  let(:owner) { create(:owner, school:) }
  let(:school) { create(:school) }

  let(:params) do
    {
      project: {
        name: 'New Name',
        components: [
          { name: 'main', extension: 'py', content: 'print("hello")' }
        ]
      }
    }
  end

  it 'responds 200 OK' do
    put("/api/projects/#{project.id}", headers:, params:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the project JSON' do
    put("/api/projects/#{project.id}", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:name]).to eq('New Name')
  end

  it 'responds with the components JSON' do
    put("/api/projects/#{project.id}", headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:components].first[:content]).to eq('print("hello")')
  end

  it 'responds 422 Unprocessable Entity when params are invalid' do
    put("/api/projects/#{project.id}", headers:, params: { project: { components: [{ name: ' ' }] } })
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'responds 401 Unauthorized when no token is given' do
    put("/api/projects/#{project.id}", params:)
    expect(response).to have_http_status(:unauthorized)
  end
end
