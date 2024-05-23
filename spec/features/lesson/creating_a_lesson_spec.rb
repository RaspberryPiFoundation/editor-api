# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a lesson', type: :request do
  before do
    authenticate_as_school_owner(owner_id:, school_id: school.id)
    stub_user_info_api_for_teacher(teacher_id:, school_id: school.id)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:teacher_id) { SecureRandom.uuid }
  let(:owner_id) { SecureRandom.uuid }
  let(:school) { create(:school) }

  let(:params) do
    {
      lesson: {
        name: 'Test Lesson'
      }
    }
  end

  it 'responds 201 Created' do
    stub_user_info_api_for_owner(owner_id:, school_id: school.id)
    post('/api/lessons', headers:, params:)
    expect(response).to have_http_status(:created)
  end

  it 'responds with the lesson JSON' do
    stub_user_info_api_for_owner(owner_id:, school_id: school.id)
    post('/api/lessons', headers:, params:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:name]).to eq('Test Lesson')
  end

  it 'responds with the user JSON which is set from the current user' do
    stub_user_info_api_for_owner(owner_id:, school_id: school.id)
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
    let(:teacher_id) { SecureRandom.uuid }

    let(:params) do
      {
        lesson: {
          name: 'Test Lesson',
          school_id: school.id,
          user_id: teacher_id
        }
      }
    end

    it 'responds 201 Created' do
      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'responds 201 Created when the user is a school-teacher for the school' do
      authenticate_as_school_teacher(teacher_id:, school_id: school.id)

      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'sets the lesson user to the specified user for school-owner users' do
      post('/api/lessons', headers:, params:)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data[:user_id]).to eq(teacher_id)
    end

    it 'sets the lesson user to the current user for school-teacher users' do
      authenticate_as_school_teacher(teacher_id:, school_id: school.id)
      new_params = { lesson: params[:lesson].merge(user_id: 'ignored') }

      post('/api/lessons', headers:, params: new_params)
      data = JSON.parse(response.body, symbolize_names: true)

      expect(data[:user_id]).to eq(teacher_id)
    end

    it 'responds 403 Forbidden when the user is a school-owner for a different school' do
      Role.teacher.find_by(user_id: teacher_id, school:).delete
      school.update!(id: SecureRandom.uuid)

      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 403 Forbidden when the user is a school-student' do
      authenticate_as_school_student(school_id: school.id)

      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'when the lesson is associated with a school class' do
    let(:school_class) { create(:school_class, teacher_id:, school:) }
    let(:school) { create(:school) }
    let(:teacher_id) { SecureRandom.uuid }

    let(:params) do
      {
        lesson: {
          name: 'Test Lesson',
          school_id: school.id,
          school_class_id: school_class.id,
          user_id: teacher_id
        }
      }
    end

    it 'responds 201 Created' do
      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:created)
    end

    it 'responds 201 Created when the user is the school-teacher for the class' do
      authenticate_as_school_teacher(teacher_id:, school_id: school.id)
      school_class.update!(teacher_id:)

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

    # rubocop:disable RSpec/ExampleLength
    it 'responds 403 Forbidden when the current user is a school-teacher for a different class' do
      teacher_id = SecureRandom.uuid
      stub_user_info_api_for_unknown_users(user_id: teacher_id)
      authenticate_as_school_teacher(school_id: school.id)
      school_class.update!(teacher_id:)

      post('/api/lessons', headers:, params:)
      expect(response).to have_http_status(:forbidden)
    end
    # rubocop:enable RSpec/ExampleLength

    it 'responds 422 Unprocessable Entity when the user_id is a school-teacher for a different class' do
      user_id = SecureRandom.uuid
      stub_user_info_api_for_unknown_users(user_id:)
      new_params = { lesson: params[:lesson].merge(user_id:) }

      post('/api/lessons', headers:, params: new_params)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
