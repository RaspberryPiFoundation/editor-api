# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a batch of lessons', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:lesson_project_params) do
    [
      {
        name: 'Lesson 1',
        school_id: school.id,
        project_attributes: { name: 'Project 1', project_type: Project::Types::CODE_EDITOR_SCRATCH }
      },
      {
        name: 'Lesson 2',
        school_id: school.id,
        project_attributes: { name: 'Project 2', project_type: Project::Types::CODE_EDITOR_SCRATCH }
      }
    ]
  end

  let(:teacher) { create(:teacher, school:) }
  let(:school) { create(:school, scratch_enabled:) }
  let(:scratch_enabled) { true }
  let(:batch_path) { '/api/lessons/batch' }
  let(:lesson_projects) { lesson_project_params }

  before do
    authenticated_in_hydra_as(teacher)
    stub_user_info_api_for(teacher)
    post(batch_path, headers:, params: { lesson_projects: })
  end

  it 'responds 201 Created' do
    expect(response).to have_http_status(:created)
  end

  it 'creates the lessons' do
    expect(Lesson.count).to eq(2)
  end

  it 'responds with the same lesson JSON shape as a single create' do
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data).to all(include(:id, :name, :user_name))
    expect(data.pluck(:name)).to contain_exactly('Lesson 1', 'Lesson 2')
  end

  it 'omits origin_identifier when not supplied' do
    data = JSON.parse(response.body, symbolize_names: true)
    expect(data).to all(satisfy { |entry| !entry.key?(:origin_identifier) })
  end

  context 'when origin_identifier is supplied' do
    let(:lesson_project_params) do
      [
        {
          name: 'Lesson 1',
          school_id: school.id,
          origin_identifier: 'curriculum-project-one',
          project_attributes: { name: 'Project 1', project_type: Project::Types::CODE_EDITOR_SCRATCH }
        },
        {
          name: 'Lesson 2',
          school_id: school.id,
          origin_identifier: 'curriculum-project-two',
          project_attributes: { name: 'Project 2', project_type: Project::Types::CODE_EDITOR_SCRATCH }
        }
      ]
    end

    it 'echoes origin_identifier on each successful entry' do
      data = JSON.parse(response.body, symbolize_names: true)
      expect(data.pluck(:origin_identifier)).to contain_exactly('curriculum-project-one', 'curriculum-project-two')
    end
  end

  context 'when some entries are invalid' do
    let(:lesson_projects) do
      lesson_project_params + [{
        name: ' ',
        school_id: school.id,
        origin_identifier: 'curriculum-project-three',
        project_attributes: { name: 'Project 3', project_type: Project::Types::CODE_EDITOR_SCRATCH }
      }]
    end

    it 'responds 201 Created' do
      expect(response).to have_http_status(:created)
    end

    it 'still creates the valid lessons' do
      expect(Lesson.count).to eq(2)
    end

    it 'echoes origin_identifier on failed entries' do
      error_entry = response.parsed_body.find { |entry| entry['error'].present? }
      expect(error_entry['origin_identifier']).to eq('curriculum-project-three')
    end
  end

  context 'when entries are associated with a school class' do
    let(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
    let(:lesson_project_params) do
      [
        {
          name: 'Lesson 1',
          school_id: school.id,
          school_class_id: school_class.id,
          project_attributes: { name: 'Project 1', project_type: Project::Types::CODE_EDITOR_SCRATCH }
        },
        {
          name: 'Lesson 2',
          school_id: school.id,
          school_class_id: school_class.id,
          project_attributes: { name: 'Project 2', project_type: Project::Types::CODE_EDITOR_SCRATCH }
        }
      ]
    end

    before do
      authenticated_in_hydra_as(teacher)
      school_class.update!(teachers: [ClassTeacher.new({ teacher_id: teacher.id })])
    end

    it 'responds 201 Created' do
      expect(response).to have_http_status(:created)
    end

    context 'when school_class_id does not correspond to school_id' do
      let(:lesson_projects) { lesson_project_params.map { |entry| entry.merge(school_id: SecureRandom.uuid) } }

      it 'responds 422 Unprocessable' do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'does not create any lessons' do
        expect(Lesson.count).to eq(0)
      end
    end

    context 'when only one entry has a mismatched school_id' do
      let(:lesson_projects) do
        [
          lesson_project_params.first,
          lesson_project_params.last.merge(school_id: SecureRandom.uuid)
        ]
      end

      it 'rejects the entire request' do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'does not create any lessons' do
        expect(Lesson.count).to eq(0)
      end
    end
  end

  context 'when the user does not belong to the school' do
    let(:other_school) { create(:school, scratch_enabled: true) }
    let(:lesson_project_params) do
      [
        {
          name: 'Lesson 1',
          school_id: other_school.id,
          project_attributes: { name: 'Project 1', project_type: Project::Types::CODE_EDITOR_SCRATCH }
        },
        {
          name: 'Lesson 2',
          school_id: other_school.id,
          project_attributes: { name: 'Project 2', project_type: Project::Types::CODE_EDITOR_SCRATCH }
        }
      ]
    end

    it 'responds 403 Forbidden' do
      expect(response).to have_http_status(:forbidden)
    end

    it 'does not create any lessons' do
      expect(Lesson.count).to eq(0)
    end
  end

  context 'when the school does not have Scratch enabled' do
    let(:scratch_enabled) { false }

    it 'returns forbidden' do
      expect(response).to have_http_status(:forbidden)
    end

    it 'does not create any lessons' do
      expect(Lesson.count).to eq(0)
    end
  end

  context 'when there lesson projects is an empty array' do
    let(:lesson_project_params) { [] }

    it 'responds 422 Unprocessable' do
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'does not create any lessons' do
      expect(Lesson.count).to eq(0)
    end
  end

  context 'when lesson projects is an array with an empty project' do
    let(:lesson_project_params) { [{}] }

    it 'responds 422 Unprocessable' do
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'does not create any lessons' do
      expect(Lesson.count).to eq(0)
    end
  end

  context 'when lesson projects is nil' do
    let(:lesson_project_params) { nil }

    it 'responds 422 Unprocessable' do
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'does not create any lessons' do
      expect(Lesson.count).to eq(0)
    end
  end
end
