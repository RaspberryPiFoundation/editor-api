# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a lesson', type: :request do
  before do
    authenticated_in_hydra_as(owner)
    stub_user_info_api_for(teacher)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:teacher) { create(:teacher, school:) }
  let(:owner) { create(:owner, school:, name: 'School Owner') }
  let(:school) { create(:school) }

  let(:params) do
    {
      lesson: {
        name: 'Test Lesson',
        project_attributes: {
          name: 'Hello world project',
          project_type: Project::Types::PYTHON,
          components: [
            { name: 'main.py', extension: 'py', content: 'print("Hello, world!")' }
          ]
        }
      }
    }
  end

  it 'responds 201 Created' do
    post('/api/lessons', headers:, params:)
    expect(response).to have_http_status(:created)
  end

  it 'responds with the lesson JSON' do
    post('/api/lessons', headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:name]).to eq('Test Lesson')
  end

  it 'responds with the user JSON which is set from the current user' do
    post('/api/lessons', headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:user_name]).to eq('School Owner')
  end

  it 'responds 422 Unprocessable Entity when params are invalid' do
    post('/api/lessons', headers:, params: { lesson: { name: ' ' } })
    expect(response).to have_http_status(:unprocessable_content)
  end

  it 'responds 401 Unauthorized when no token is given' do
    post('/api/lessons', params:)
    expect(response).to have_http_status(:unauthorized)
  end

  context 'when the lesson is associated with a school (library)' do
    let(:school) { create(:school) }
    let(:teacher) { create(:teacher, school:) }

    let(:params) do
      {
        lesson: {
          name: 'Test Lesson',
          school_id: school.id,
          project_attributes: {
            name: 'Hello world project',
            project_type: Project::Types::PYTHON,
            components: [
              { name: 'main.py', extension: 'py', content: 'print("Hello, world!")' }
            ]
          }
        }
      }
    end

    it 'responds 201 Created' do
      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'responds 201 Created when the user is a school-teacher for the school' do
      authenticated_in_hydra_as(teacher)

      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'sets the lesson user to the current user for school-teacher users' do
      authenticated_in_hydra_as(teacher)
      new_params = { lesson: params[:lesson].merge(user_id: 'ignored') }

      post('/api/lessons', headers:, params: new_params)
      expect(response).to have_http_status(:created)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data[:user_id]).to eq(teacher.id)
    end

    it 'responds 403 Forbidden when the user is a school-owner for a different school' do
      Role.teacher.find_by(user_id: teacher.id, school:).delete
      Role.owner.find_by(user_id: owner.id, school:).delete
      school.update!(id: SecureRandom.uuid)

      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 403 Forbidden when the user is a school-student' do
      student = create(:student, school:)
      authenticated_in_hydra_as(student)

      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'when bulk creating lessons via lesson_projects' do
    before { school.update!(scratch_enabled: true) }

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

    it 'responds 201 Created' do
      post('/api/lessons', headers:, params: { lesson_projects: lesson_project_params })
      expect(response).to have_http_status(:created)
    end

    it 'creates one lesson per entry' do
      expect do
        post('/api/lessons', headers:, params: { lesson_projects: lesson_project_params })
      end.to change(Lesson, :count).by(2)
    end

    it 'responds with the same lesson JSON shape as a single create' do
      post('/api/lessons', headers:, params: { lesson_projects: lesson_project_params })
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data).to all(include(:id, :name, :user_name))
      expect(data.pluck(:name)).to contain_exactly('Lesson 1', 'Lesson 2')
    end

    it 'omits origin_identifier when not supplied' do
      post('/api/lessons', headers:, params: { lesson_projects: lesson_project_params })
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
        post('/api/lessons', headers:, params: { lesson_projects: lesson_project_params })
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data.pluck(:origin_identifier)).to contain_exactly('curriculum-project-one', 'curriculum-project-two')
      end
    end

    context 'when some entries are invalid' do
      let(:invalid_lesson_project_params) do
        lesson_project_params + [{
          name: ' ',
          school_id: school.id,
          origin_identifier: 'curriculum-project-three',
          project_attributes: { name: 'Project 3', project_type: Project::Types::CODE_EDITOR_SCRATCH }
        }]
      end

      it 'responds 201 Created' do
        post('/api/lessons', headers:, params: { lesson_projects: invalid_lesson_project_params })
        expect(response).to have_http_status(:created)
      end

      it 'includes an error entry for the failed lesson' do
        post('/api/lessons', headers:, params: { lesson_projects: invalid_lesson_project_params })
        expect(response.parsed_body.any? { |entry| entry['error'].present? }).to be true
      end

      it 'still creates the valid lessons' do
        expect do
          post('/api/lessons', headers:, params: { lesson_projects: invalid_lesson_project_params })
        end.to change(Lesson, :count).by(2)
      end

      it 'echoes origin_identifier on failed entries' do
        post('/api/lessons', headers:, params: { lesson_projects: invalid_lesson_project_params })
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
        post('/api/lessons', headers:, params: { lesson_projects: lesson_project_params })

        expect(response).to have_http_status(:created)
      end

      it 'responds 422 Unprocessable if school_class_id does not correspond to school_id' do
        mismatched_params = lesson_project_params.map { |entry| entry.merge(school_id: SecureRandom.uuid) }

        post('/api/lessons', headers:, params: { lesson_projects: mismatched_params })

        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'does not create any lessons when school_class_id does not correspond to school_id' do
        mismatched_params = lesson_project_params.map { |entry| entry.merge(school_id: SecureRandom.uuid) }

        expect do
          post('/api/lessons', headers:, params: { lesson_projects: mismatched_params })
        end.not_to change(Lesson, :count)
      end

      it 'rejects the request when only one entry has a mismatched school_id' do
        mismatched_params = [
          lesson_project_params.first,
          lesson_project_params.last.merge(school_id: SecureRandom.uuid)
        ]

        expect do
          post('/api/lessons', headers:, params: { lesson_projects: mismatched_params })
        end.not_to change(Lesson, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  context 'when the lesson is associated with a school class' do
    let(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
    let(:school) { create(:school) }
    let(:teacher) { create(:teacher, school:) }

    let(:params) do
      {
        lesson: {
          name: 'Test Lesson',
          school_id: school.id,
          school_class_id: school_class.id,
          project_attributes: {
            name: 'Hello world project',
            project_type: Project::Types::PYTHON,
            components: [
              { name: 'main.py', extension: 'py', content: 'print("Hello, world!")' }
            ]
          }
        }
      }
    end

    it 'responds 201 Created when the user is the school-teacher for the class' do
      authenticated_in_hydra_as(teacher)
      school_class.update!(teachers: [ClassTeacher.new({ teacher_id: teacher.id })])

      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'responds 422 Unprocessable if school_id is missing' do
      new_params = { lesson: params[:lesson].without(:school_id) }

      post('/api/lessons', headers:, params: new_params)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'responds 422 Unprocessable if school_class_id does not correspond to school_id' do
      new_params = { lesson: params[:lesson].merge(school_id: SecureRandom.uuid) }

      post('/api/lessons', headers:, params: new_params)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'responds 403 Forbidden when the user is a school-owner for a different school' do
      school = create(:school, id: SecureRandom.uuid)
      school_class.update!(school_id: school.id)
      params[:lesson][:school_id] = school.id

      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 403 Forbidden when the current user is a school-teacher for a different class' do
      teacher = create(:teacher, school:)
      authenticated_in_hydra_as(teacher)

      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 422 Unprocessable Entity when the user_id is a school-teacher for a different class' do
      user_id = SecureRandom.uuid
      new_params = { lesson: params[:lesson].merge(user_id:) }

      post('/api/lessons', headers:, params: new_params)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'working with Scratch projects' do
    let(:params) do
      {
        lesson: {
          name: 'Test Lesson',
          school_id: school.id,
          project_attributes: {
            name: 'Hello Scratch project',
            project_type: Project::Types::CODE_EDITOR_SCRATCH,
            scratch_component: {
              content: {
                example_data: 'true'
              }
            }
          }
        }
      }
    end

    it 'creates a lesson with a scratch component when school has Scratch enabled' do
      school.update!(scratch_enabled: true)
      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:created)

      data = JSON.parse(response.body, symbolize_names: true)

      lesson_id = data[:id]

      project = Lesson.find(lesson_id).project
      expect(project.project_type).to eq(Project::Types::CODE_EDITOR_SCRATCH)
      expect(project.scratch_component.content).to eq({ 'example_data' => 'true' })
    end

    it 'returns forbidden when school does not have Scratch enabled' do
      school.update!(scratch_enabled: false)
      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
