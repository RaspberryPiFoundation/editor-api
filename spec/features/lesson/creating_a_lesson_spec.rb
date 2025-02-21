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
          project_type: 'python',
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
    expect(response).to have_http_status(:unprocessable_entity)
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
            project_type: 'python',
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
            project_type: 'python',
            components: [
              { name: 'main.py', extension: 'py', content: 'print("Hello, world!")' }
            ]
          }
        }
      }
    end

    it 'responds 201 Created when the user is the school-teacher for the class' do
      authenticated_in_hydra_as(teacher)
      school_class.update!(class_teachers: [ClassTeacher.new({teacher_id: teacher.id})])

      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'responds 422 Unprocessable if school_id is missing' do
      new_params = { lesson: params[:lesson].without(:school_id) }

      post('/api/lessons', headers:, params: new_params)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'responds 422 Unprocessable if school_class_id does not correspond to school_id' do
      new_params = { lesson: params[:lesson].merge(school_id: SecureRandom.uuid) }

      post('/api/lessons', headers:, params: new_params)
      expect(response).to have_http_status(:unprocessable_entity)
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
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
