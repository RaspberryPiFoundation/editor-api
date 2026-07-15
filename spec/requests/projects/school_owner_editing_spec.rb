# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'School owner class project editing' do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:owner) { create(:owner, school:) }
  let(:teacher) { create(:teacher, school:) }
  let(:teacher_ids) { [teacher.id, (owner.id if owner_in_class)].compact }
  let(:school_class) { create(:school_class, school:, teacher_ids:) }
  let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'teachers') }
  let(:project_user) { project_created_by_owner ? owner : teacher }
  let(:project) { create(:project, school:, lesson:, user_id: project_user.id, project_type:, locale: nil) }

  before do
    authenticated_in_hydra_as(owner)
    create(:scratch_component, project:) if project.scratch_project?
  end

  project_types = [
    ['Python', Project::Types::PYTHON],
    ['Scratch', Project::Types::CODE_EDITOR_SCRATCH]
  ]
  ownership_cases = [
    ['created by the owner in their class', true, true],
    ['created by the owner outside their class', true, false],
    ['created by another teacher in the owner\'s class', false, true],
    ['created by another teacher outside the owner\'s class', false, false]
  ]

  project_types.product(ownership_cases).each do |(type_name, type), (case_name, created_by_owner, in_class)|
    context "with a #{type_name} project #{case_name}" do
      let(:project_type) { type }
      let(:project_created_by_owner) { created_by_owner }
      let(:owner_in_class) { in_class }

      it 'loads as editable and updates the original project' do
        get("/api/projects/#{project.identifier}", headers:)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['user_id']).to eq(owner.id)

        project_count = Project.count
        if project.scratch_project?
          put("/api/scratch/projects/#{project.identifier}", params: { targets: ['owner update'] }, headers:)
          expect(project.reload.scratch_component.content.to_h['targets']).to eq(['owner update'])
        else
          put("/api/projects/#{project.identifier}", params: { project: { name: 'owner update' } }, headers:)
          expect(project.reload.name).to eq('owner update')
        end

        expect(response).to have_http_status(:ok)
        expect(Project.count).to eq(project_count)
        expect(project.reload.user_id).to eq(project_user.id)
      end
    end
  end
end
