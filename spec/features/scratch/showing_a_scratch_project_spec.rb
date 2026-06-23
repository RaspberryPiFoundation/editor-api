# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Showing a Scratch project', type: :request do
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:) }
  let(:student) { create(:student, school:) }
  let(:headers) { { 'Authorization' => UserProfileMock::TOKEN } }
  let(:school_class) { create(:school_class, school:, teacher_ids: [teacher.id]) }
  let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id) }

  it 'returns scratch project JSON' do
    authenticated_in_hydra_as(teacher)
    project = create(
      :project,
      project_type: Project::Types::CODE_EDITOR_SCRATCH,
      locale: 'en',
      school: school,
      user_id: teacher.id,
      lesson: lesson
    )
    create(:scratch_component, project: project)

    get "/api/scratch/projects/#{project.identifier}", headers: headers

    expect(response).to have_http_status(:ok)

    data = JSON.parse(response.body, symbolize_names: true)
    expect(data).to have_key(:targets)
  end

  it 'returns the stage target first when stored targets are out of order' do
    authenticated_in_hydra_as(teacher)
    project = create(
      :project,
      project_type: Project::Types::CODE_EDITOR_SCRATCH,
      locale: 'en',
      school: school,
      lesson: lesson,
      user_id: teacher.id
    )
    create(
      :scratch_component,
      project:,
      content: {
        targets: [
          { name: 'Sprite1', isStage: false },
          { name: 'Stage', isStage: true },
          { name: 'Sprite2', isStage: false }
        ]
      }
    )

    get "/api/scratch/projects/#{project.identifier}", headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('targets').pluck('name')).to eq(%w[Stage Sprite1 Sprite2])
  end

  it 'returns a 404 if project does not exist' do
    authenticated_in_hydra_as(teacher)
    get '/api/scratch/projects/non_existent_project', headers: headers

    expect(response).to have_http_status(:not_found)
  end

  it 'returns a 404 if project is not a scratch project' do
    authenticated_in_hydra_as(teacher)
    project = create(:project, project_type: Project::Types::PYTHON, locale: 'en')

    get "/api/scratch/projects/#{project.identifier}", headers: headers

    expect(response).to have_http_status(:not_found)
  end

  it 'returns a 200 ok if not logged in for an anonymous scratch project' do
    project = create(:scratch_project, locale: 'en', user_id: nil)
    get "/api/scratch/projects/#{project.identifier}"

    expect(response).to have_http_status(:ok)
  end

  it 'returns a 200 ok if logged in for an anonymous scratch project' do
    authenticated_in_hydra_as(student)
    project = create(:scratch_project, locale: 'en', user_id: nil)
    get "/api/scratch/projects/#{project.identifier}", headers: headers

    expect(response).to have_http_status(:ok)
  end

  it 'returns a 403 forbidden if user does not have access to the project' do
    authenticated_in_hydra_as(teacher)
    project = create(
      :project,
      project_type: Project::Types::CODE_EDITOR_SCRATCH,
      locale: 'en'
    )
    create(:scratch_component, project: project)

    get "/api/scratch/projects/#{project.identifier}", headers: headers

    expect(response).to have_http_status(:forbidden)
  end
end
