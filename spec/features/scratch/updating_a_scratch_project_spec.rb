# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Updating a Scratch project', type: :request do
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:) }
  let(:auth_headers) { { 'Authorization' => UserProfileMock::TOKEN } }

  it 'responds 401 Unauthorized when no Authorization header is provided' do
    put '/api/scratch/projects/any-identifier', params: { project: { targets: [] } }

    expect(response).to have_http_status(:unauthorized)
  end

  it 'updates a project when an Authorization header is provided' do
    authenticated_in_hydra_as(teacher)
    project = create(
      :project,
      project_type: Project::Types::CODE_EDITOR_SCRATCH,
      locale: 'en'
    )
    create(:scratch_component, project: project)

    put "/api/scratch/projects/#{project.identifier}", params: { targets: ['some update'] }, headers: auth_headers

    expect(response).to have_http_status(:ok)

    data = JSON.parse(response.body, symbolize_names: true)
    expect(data[:status]).to eq('ok')

    expect(project.reload.scratch_component.content.to_h['targets']).to eq(['some update'])
  end
end
