# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a Scratch asset', type: :request do
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:) }
  let(:project) do
    create(:project, project_type: Project::Types::CODE_EDITOR_SCRATCH, locale: nil, user_id: teacher.id).tap do |scratch_project|
      create(:scratch_component, project: scratch_project)
    end
  end
  let(:auth_headers) { { 'Authorization' => UserProfileMock::TOKEN } }
  let(:project_headers) { auth_headers.merge('X-Project-ID' => project.identifier) }

  before do
    Flipper.enable_actor :cat_mode, school
  end

  it 'responds 401 Unauthorized when no Authorization header is provided' do
    post '/api/scratch/assets/example.svg', headers: { 'X-Project-ID' => project.identifier }

    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 404 Not Found when cat_mode is not enabled' do
    authenticated_in_hydra_as(teacher)
    Flipper.disable :cat_mode
    Flipper.disable_actor :cat_mode, school

    post '/api/scratch/assets/example.svg', headers: project_headers

    expect(response).to have_http_status(:not_found)
  end

  it 'creates an asset when cat_mode is enabled and the required headers are provided' do
    authenticated_in_hydra_as(teacher)

    post '/api/scratch/assets/example.svg', headers: project_headers

    expect(response).to have_http_status(:created)

    data = JSON.parse(response.body, symbolize_names: true)
    expect(data[:status]).to eq('ok')
    expect(data[:'content-name']).to eq('example')
  end
end
