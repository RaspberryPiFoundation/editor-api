# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Updating a Scratch project', type: :request do
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:) }
  let(:auth_headers) { { 'Authorization' => UserProfileMock::TOKEN } }
  let(:school_class) { create(:school_class, school:, teacher_ids: [teacher.id]) }
  let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id) }

  it 'responds 401 Unauthorized when no Authorization header is provided' do
    put '/api/scratch/projects/any-identifier', params: { project: { targets: [] } }

    expect(response).to have_http_status(:unauthorized)
  end

  it 'updates a project when an Authorization header is provided' do
    authenticated_in_hydra_as(teacher)
    project = create(
      :project,
      project_type: Project::Types::CODE_EDITOR_SCRATCH,
      locale: 'en',
      school: school,
      lesson: lesson,
      user_id: teacher.id
    )
    create(:scratch_component, project: project)

    put "/api/scratch/projects/#{project.identifier}", params: { targets: ['some update'] }, headers: auth_headers

    expect(response).to have_http_status(:ok)

    data = JSON.parse(response.body, symbolize_names: true)
    expect(data[:status]).to eq('ok')

    expect(project.reload.scratch_component.content.to_h['targets']).to eq(['some update'])
    expect(Event.last).to have_attributes(
      name: 'Project - Saved',
      user_id: teacher.id,
      properties: {
        'school_id' => school.id,
        'class_id' => school_class.id,
        'lesson_id' => lesson.id,
        'project_type' => Project::Types::CODE_EDITOR_SCRATCH,
        'user_role' => 'educator'
      },
      time: be_within(1.second).of(Time.current)
    )
  end

  it 'returns 403 Forbidden when trying to update a project user does not have access to' do
    authenticated_in_hydra_as(teacher)
    project = create(
      :project,
      project_type: Project::Types::CODE_EDITOR_SCRATCH,
      locale: 'en'
    )
    create(:scratch_component, project: project)

    put "/api/scratch/projects/#{project.identifier}", params: { targets: ['some update'] }, headers: auth_headers

    expect(response).to have_http_status(:forbidden)
  end
end
