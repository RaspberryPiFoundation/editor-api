# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a public lesson', type: :request do
  before do
    stub_hydra_public_api
    stub_user_info_api
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }

  let(:params) do
    {
      lesson: {
        name: 'Test Lesson'
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

  it 'responds 400 Bad Request when params are missing' do
    post('/api/lessons', headers:)
    expect(response).to have_http_status(:bad_request)
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

    let(:params) do
      {
        lesson: {
          name: 'Test Lesson',
          school_id: school.id
        }
      }
    end

    it 'responds 201 Created' do
      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'responds 201 Created when the user is a school-teacher for the school' do
      stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))

      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'responds 403 Forbidden when the user is a school-owner for a different school' do
      school.update!(id: SecureRandom.uuid)

      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 403 Forbidden when the user is a school-student' do
      stub_hydra_public_api(user_index: user_index_by_role('school-student'))

      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'when the lesson is associated with a school class' do
    let(:school_class) { create(:school_class) }
    let(:school) { school_class.school }

    let(:params) do
      {
        lesson: {
          name: 'Test Lesson',
          school_id: school.id,
          school_class_id: school_class.id
        }
      }
    end

    it 'responds 201 Created' do
      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'responds 201 Created when the user is the school-teacher for the class' do
      teacher_index = user_index_by_role('school-teacher')

      stub_hydra_public_api(user_index: teacher_index)
      school_class.update!(teacher_id: user_id_by_index(teacher_index))

      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'responds 403 Forbidden when the user is a school-owner for a different school' do
      school = create(:school, id: SecureRandom.uuid)
      school_class.update!(school_id: school.id)

      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 403 Forbidden when the user is a school-teacher for a different class' do
      stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))
      school_class.update!(teacher_id: SecureRandom.uuid)

      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
