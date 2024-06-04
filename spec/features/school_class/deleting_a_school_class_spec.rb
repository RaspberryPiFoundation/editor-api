# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deleting a school class', type: :request do
  before do
    authenticate_as_school_owner(school_id: school.id)
    stub_user_info_api_for_teacher(teacher_id:, school:)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:school_class) { create(:school_class, teacher_id:, school:) }
  let(:school) { create(:school) }
  let(:teacher_id) { SecureRandom.uuid }

  it 'responds 204 No Content' do
    delete("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 204 No Content when the user is the class teacher' do
    authenticate_as_school_teacher(teacher_id:, school_id: school.id)

    delete("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 401 Unauthorized when no token is given' do
    delete "/api/schools/#{school.id}/classes/#{school_class.id}"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school = create(:school, id: SecureRandom.uuid)
    school_class.update!(school_id: school.id)

    delete("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  # rubocop:disable RSpec/ExampleLength
  it 'responds 403 Forbidden when the user is not the school-teacher for the class' do
    teacher_id = SecureRandom.uuid
    stub_user_info_api_for_unknown_users(user_id: teacher_id)
    authenticate_as_school_teacher(school_id: school.id)
    school_class.update!(teacher_id:)

    delete("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end
  # rubocop:enable RSpec/ExampleLength

  it 'responds 403 Forbidden when the user is a school-student' do
    authenticate_as_school_student(school_id: school.id)

    delete("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
