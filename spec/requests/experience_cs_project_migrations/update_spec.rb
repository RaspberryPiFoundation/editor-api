# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Experience CS project migration requests' do
  let(:headers) { { ExperienceCsServiceAuthenticator::HEADER => 'service-api-key' } }
  let(:school) { create(:school) }
  let(:owner) { create(:teacher, school:) }
  let(:project) do
    create(
      :project,
      identifier: 'user-project-stub',
      school:,
      user_id: owner.id,
      locale: nil,
      project_type: Project::Types::SCRATCH
    )
  end
  let(:scratch_data) { { targets: [], monitors: [], extensions: [], meta: {} } }
  let(:params) do
    {
      project: {
        name: 'Migrated project',
        instructions: [{ markdown_content: 'Make the sprite move.' }],
        scratch_component: { content: scratch_data }
      }
    }
  end
  let(:path) { '/api/experience-cs/projects/user-project-stub/migrate' }

  before do
    project
    allow(Rails.configuration.x.experience_cs).to receive(:service_api_key).and_return('service-api-key')
  end

  it 'replaces the exact stub in place' do
    original_id = project.id

    put(path, params:, headers:, as: :json)

    expect(response).to have_http_status(:ok)
    expect(project.reload).to have_attributes(
      id: original_id,
      identifier: 'user-project-stub',
      locale: nil,
      user_id: owner.id,
      school_id: school.id,
      name: 'Migrated project',
      instructions: [{ 'markdown_content' => 'Make the sprite move.' }],
      project_type: Project::Types::CODE_EDITOR_SCRATCH
    )
    expect(project.scratch_component.content.to_h).to eq(scratch_data.deep_stringify_keys)
  end

  it 'rejects a replay without overwriting Code Classroom changes' do
    put(path, params:, headers:, as: :json)
    code_classroom_data = scratch_data.merge(meta: { updated_in_code_classroom: true })
    project.reload.scratch_component.update!(content: code_classroom_data)

    put(path, params:, headers:, as: :json)

    expect(response).to have_http_status(:forbidden)
    expect(project.reload.scratch_component.content.to_h).to eq(code_classroom_data.deep_stringify_keys)
  end

  it 'does not authorize a human Experience CS admin' do
    authenticated_in_hydra_as(create(:experience_cs_admin_user))

    put(path, params:, headers: { Authorization: UserProfileMock::TOKEN }, as: :json)

    expect(response).to have_http_status(:forbidden)
  end

  it 'does not overwrite a native Code Classroom project' do
    project.update!(project_type: Project::Types::CODE_EDITOR_SCRATCH)

    put(path, params:, headers:, as: :json)

    expect(response).to have_http_status(:forbidden)
  end

  it 'does not fall back to a public locale' do
    project.destroy!
    public_project = create(
      :project,
      identifier: 'user-project-stub',
      locale: 'en',
      user_id: nil,
      project_type: Project::Types::SCRATCH
    )

    put(path, params:, headers:, as: :json)

    expect(response).to have_http_status(:not_found)
    expect(public_project.reload.project_type).to eq(Project::Types::SCRATCH)
  end
end
