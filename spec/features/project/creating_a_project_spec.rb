# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a project', type: :request do
  before do
    authenticated_in_hydra_as(teacher)
    mock_phrase_generation
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:teacher) { create(:teacher, school:) }
  let(:school) { create(:school) }
  let(:owner) { create(:owner, school:) }

  let(:params) do
    {
      project: {
        name: 'Test Project',
        components: [
          { name: 'main', extension: 'py', content: 'print("hi")' }
        ]
      }
    }
  end

  it 'responds 201 Created' do
    post('/api/projects', headers:, params:)
    expect(response).to have_http_status(:created)
  end

  it 'responds with the project JSON' do
    post('/api/projects', headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:name]).to eq('Test Project')
  end

  it 'responds with the components JSON' do
    post('/api/projects', headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:components].first[:content]).to eq('print("hi")')
  end

  it 'responds 422 Unprocessable Entity when params are invalid' do
    post('/api/projects', headers:, params: { project: { components: [{ name: ' ' }] } })
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'responds 401 Unauthorized when no token is given' do
    post('/api/projects', params:)
    expect(response).to have_http_status(:unauthorized)
  end

  context 'when the project is associated with a school (library)' do
    let(:school) { create(:school) }
    let(:teacher) { create(:teacher, school:) }

    let(:params) do
      {
        project: {
          name: 'Test Project',
          components: [],
          school_id: school.id,
          user_id: teacher.id
        }
      }
    end

    it 'responds 201 Created' do
      post('/api/projects', headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'responds 201 Created when the user is a school-teacher for the school' do
      authenticated_in_hydra_as(teacher)

      post('/api/projects', headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'responds 403 Forbidden when the user is a school-student for the school' do
      student = create(:student, school:)
      authenticated_in_hydra_as(student)

      post('/api/projects', headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end

    it 'sets the lesson user to the specified user for school-owner users' do
      post('/api/projects', headers:, params:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data[:user_id]).to eq(teacher.id)
    end

    it 'sets the project user to the current user for school-teacher users' do
      authenticated_in_hydra_as(teacher)
      new_params = { project: params[:project].merge(user_id: 'ignored') }

      post('/api/projects', headers:, params: new_params)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data[:user_id]).to eq(teacher.id)
    end

    it 'responds 403 Forbidden when the user is a school-owner for a different school' do
      Role.teacher.find_by(user_id: teacher.id, school:).delete
      Role.owner.find_by(user_id: owner.id, school:).delete
      school.update!(id: SecureRandom.uuid)

      post('/api/projects', headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'when the project is associated with a lesson' do
    let(:school) { create(:school) }
    let(:lesson) { create(:lesson, school:, user_id: teacher.id) }
    let(:lesson_created_by_owner) { create(:lesson, school:, user_id: owner.id) }
    let(:teacher) { create(:teacher, school:) }

    let(:params) do
      {
        project: {
          name: 'Test Project',
          components: [],
          school_id: school.id,
          lesson_id: lesson.id,
          user_id: teacher.id
        }
      }
    end

    it 'responds 201 Created' do
      post('/api/projects', headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'responds 201 Created when the current user is the owner of the lesson' do
      authenticated_in_hydra_as(teacher)
      lesson.update!(user_id: teacher.id)

      post('/api/projects', headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'responds 422 Unprocessable when when the user_id is not the owner of the lesson' do
      user_id = SecureRandom.uuid
      project = {
        project: {
          name: 'Test Project',
          components: [],
          school_id: school.id,
          lesson_id: lesson_created_by_owner.id,
          user_id: teacher.id
        }
      }
      new_params = { project: project.merge(user_id:) }

      post('/api/projects', headers:, params: new_params)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'responds 422 Unprocessable when lesson_id is provided but school_id is missing' do
      new_params = { project: params[:project].without(:school_id) }

      post('/api/projects', headers:, params: new_params)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'responds 422 Unprocessable when lesson_id does not correspond to school_id' do
      new_params = { project: params[:project].merge(lesson_id: SecureRandom.uuid) }

      post('/api/projects', headers:, params: new_params)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'responds 403 Forbidden when the user is a school-owner for a different school' do
      new_params = { project: params[:project].without(:lesson_id).merge(school_id: SecureRandom.uuid) }

      post('/api/projects', headers:, params: new_params)
      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 403 Forbidden when the current user is not the owner of the lesson' do
      teacher = create(:teacher, school:)
      authenticated_in_hydra_as(teacher)

      post('/api/projects', headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 403 Forbidden when the user is a school-student' do
      student = create(:student, school:)
      authenticated_in_hydra_as(student)

      post('/api/projects', headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
