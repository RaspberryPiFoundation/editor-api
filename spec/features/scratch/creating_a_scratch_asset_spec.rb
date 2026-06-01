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
  let(:headers) { { 'Authorization' => UserProfileMock::TOKEN, 'X-Project-ID' => project.identifier } }

  it 'responds 401 Unauthorized when no Authorization header is provided' do
    post '/api/scratch/assets/example.svg', headers: { 'X-Project-ID' => project.identifier }

    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 404 Not Found when user is not part of a school' do
    user = create(:user)
    authenticated_in_hydra_as(user)

    post '/api/scratch/assets/example.svg', headers: headers

    expect(response).to have_http_status(:not_found)
  end

  it 'creates an asset when user is part of a school and the required headers are provided' do
    authenticated_in_hydra_as(teacher)

    post '/api/scratch/assets/example.svg', headers: headers

    expect(response).to have_http_status(:created)

    data = JSON.parse(response.body, symbolize_names: true)
    expect(data[:status]).to eq('ok')
    expect(data[:'content-name']).to eq('example')
  end
end
