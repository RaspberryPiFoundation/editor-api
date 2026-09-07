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

    it 'records project created events for each created lesson project' do
      events = Event.where(name: 'Project - Created')

      expect(events.count).to eq(2)
      expect(events.map(&:user_id)).to all(eq(teacher.id))
      expect(events.map(&:properties)).to match_array(
        Lesson.order(:created_at).map do |lesson|
          {
            'school_id' => school.id,
            'class_id' => school_class.id,
            'lesson_id' => lesson.id,
            'project_type' => Project::Types::CODE_EDITOR_SCRATCH,
            'user_role' => 'educator'
          }
        end
      )
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

  # #create_batch resolves each row's `source_project_identifier` through
  # ProjectLoader, authorizes it, and hands the Project to Lesson::CreateBatch
  # so that row's lesson project is built as a remix instead of a stub.
  context 'when entries reference source projects' do
    let(:source_content) { { 'targets' => [{ 'name' => 'Stage' }], 'monitors' => [], 'extensions' => [], 'meta' => {} } }

    let!(:source_project) do
      create(:scratch_project, identifier: 'my-digital-canvas', locale: 'en', user_id: nil, school_id: nil,
                               name: 'My digital canvas', origin: Project::Origins::EXPERIENCE_CS)
        .tap { |project| project.scratch_component.update!(content: source_content) }
    end

    let(:lesson_project_params) do
      [
        {
          name: 'Lesson 1',
          school_id: school.id,
          source_project_identifier: source_project.identifier,
          project_attributes: { name: 'My digital canvas', locale: 'en' }
        },
        {
          name: 'Lesson 2',
          school_id: school.id,
          project_attributes: { name: 'Project 2', locale: 'en' }
        }
      ]
    end

    let(:lesson_projects_json) { JSON.parse(response.body, symbolize_names: true) }
    let(:lesson_project_with_source) { Lesson.find(lesson_projects_json.first[:id]).project }
    let(:stub_lesson_project) { Lesson.find(lesson_projects_json.second[:id]).project }

    it 'responds 201 Created' do
      expect(response).to have_http_status(:created)
    end

    it 'records the source project on the lesson_project_with_source' do
      expect(lesson_project_with_source.source_project_id).to eq(source_project.id)
    end

    it 'sets the lesson_project_with_source locale to nil' do
      expect(lesson_project_with_source.locale).to be_nil
    end

    it 'leaves source_project_identifier as nil in the stub project' do
      expect(stub_lesson_project.source_project_id).to be_nil
    end

    context 'when the source project cannot be found' do
      let(:lesson_project_params) do
        [
          {
            name: 'Lesson 1',
            school_id: school.id,
            source_project_identifier: 'does-not-exist',
            project_attributes: { name: 'My digital canvas', locale: 'en' }
          }
        ]
      end

      it 'responds 422 Unprocessable' do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'does not create any lessons' do
        expect(Lesson.count).to eq(0)
      end
    end

    context 'when a source_project_identifier points at a scratch project and the school does not have Scratch enabled' do
      let(:scratch_enabled) { false }

      it 'responds 403 Forbidden' do
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not create any lessons' do
        expect(Lesson.count).to eq(0)
      end
    end
  end
end
