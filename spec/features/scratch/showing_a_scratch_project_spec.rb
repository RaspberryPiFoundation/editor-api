# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Showing a Scratch project', type: :request do
  it 'returns scratch project JSON' do
    project = create(
      :project,
      project_type: Project::Types::CODE_EDITOR_SCRATCH,
      locale: 'en'
    )
    create(:scratch_component, project: project)

    get "/api/scratch/projects/#{project.identifier}"

    expect(response).to have_http_status(:ok)

    data = JSON.parse(response.body, symbolize_names: true)
    expect(data).to have_key(:targets)
  end

  it 'returns a 404 if project does not exist' do
    get '/api/scratch/projects/non_existent_project'

    expect(response).to have_http_status(:not_found)
  end

  it 'returns a 404 if project is not a scratch project' do
    project = create(:project, project_type: Project::Types::PYTHON, locale: 'en')

    get "/api/scratch/projects/#{project.identifier}"

    expect(response).to have_http_status(:not_found)
  end
end
