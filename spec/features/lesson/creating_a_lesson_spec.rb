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

    it 'records a project created event' do
      authenticated_in_hydra_as(teacher)

      post('/api/lessons', headers:, params:)

      expect(Event.last).to have_attributes(
        name: 'Project - Created',
        user_id: teacher.id,
        properties: {
          'school_id' => school.id,
          'class_id' => school_class.id,
          'lesson_id' => Lesson.last.id,
          'project_type' => Project::Types::PYTHON,
          'user_role' => 'educator'
        },
        time: be_within(1.second).of(Time.current)
      )
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

  # #create resolves `lesson[:source_project_identifier]` through
  # ProjectLoader, authorizes it, and hands the Project to Lesson::Create
  # so the lesson project is built as a remix instead of a stub.
  describe 'creating a lesson from a source project' do
    let(:source_content) { { 'targets' => [{ 'name' => 'Stage' }], 'monitors' => [], 'extensions' => [], 'meta' => {} } }

    let!(:source_project) do
      create(:scratch_project, identifier: 'my-digital-canvas', locale: 'en', user_id: nil, school_id: nil,
                               name: 'My digital canvas', origin: Project::Origins::EXPERIENCE_CS,
                               instructions: 'English instructions')
        .tap { |project| project.scratch_component.update!(content: source_content) }
    end

    let(:params) do
      {
        lesson: {
          name: 'Test Lesson',
          school_id: school.id,
          source_project_identifier: source_project.identifier,
          project_attributes: {
            name: 'My digital canvas',
            locale: 'en'
          }
        }
      }
    end

    let(:lesson_project) { Lesson.find(JSON.parse(response.body, symbolize_names: true)[:id]).project }

    context 'when the source project is a shared Experience CS project' do
      before do
        post('/api/lessons', headers:, params:)
      end

      it 'responds 201 Created' do
        expect(response).to have_http_status(:created)
      end

      it 'responds with the lesson JSON' do
        data = JSON.parse(response.body, symbolize_names: true)

        expect(data[:name]).to eq('Test Lesson')
      end

      it 'copies the scratch component content from the source project' do
        expect(lesson_project.scratch_component.content).to eq(source_content)
      end

      it 'gives the lesson project a new identifier' do
        expect(lesson_project.identifier).not_to eq(source_project.identifier)
      end

      it 'sets the lesson project locale to nil' do
        expect(lesson_project.locale).to be_nil
      end

      it 'inherits project_type from the source project' do
        expect(lesson_project.project_type).to eq(source_project.project_type)
      end

      it 'inherits origin from the source project' do
        expect(lesson_project.origin).to eq(source_project.origin)
      end
    end

    context 'when choosing the locale of the source project' do
      # ProjectLoader is given [project_attributes[:locale]] and falls back to 'en' then nil.
      it 'remixes the row matching the requested locale when one exists'

      it 'falls back to the en row when the requested locale does not exist'
    end

    context 'when the source project cannot be used' do
      it 'responds 422 Unprocessable Entity when no project matches the identifier'

      it 'responds 422 Unprocessable Entity when the source scratch project is not an Experience CS project'

      # find_source_project! returns nil for non-scratch projects, so the stub path is kept.
      it 'ignores a non-scratch source project and builds a stub project from project_attributes'
    end

    context 'when the user cannot view the source project' do
      it 'responds 403 Forbidden when the source project belongs to another user'
    end

    context 'when the school does not have Scratch enabled' do
      # verify_can_create_scratch_projects reads project_attributes[:project_type], which a
      # source-project request need not send — decide whether the source project type should
      # also be gated here.
      it 'responds 403 Forbidden when only source_project_identifier points at a scratch project'
    end
  end
end
