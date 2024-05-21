# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deleting a class member', type: :request do
  before do
    authenticate_as_school_owner
    stub_user_info_api_for_teacher(teacher_id: User::TEACHER_ID)
    stub_user_info_api_for_student(student_id:, school_id: School::ID)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:class_member) { create(:class_member, student_id:, school_class:) }
  let(:school_class) { build(:school_class, teacher_id: User::TEACHER_ID) }
  let(:school) { school_class.school }
  let(:student_id) { User::STUDENT_ID }

  it 'responds 204 No Content' do
    delete("/api/schools/#{school.id}/classes/#{school_class.id}/members/#{class_member.id}", headers:)
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 204 No Content when the user is the class teacher' do
    authenticate_as_school_teacher

    delete("/api/schools/#{school.id}/classes/#{school_class.id}/members/#{class_member.id}", headers:)
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 401 Unauthorized when no token is given' do
    delete "/api/schools/#{school.id}/classes/#{school_class.id}/members/#{class_member.id}"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school = create(:school, id: SecureRandom.uuid)
    school_class.update!(school_id: school.id)

    delete("/api/schools/#{school.id}/classes/#{school_class.id}/members/#{class_member.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  # rubocop:disable RSpec/ExampleLength
  it 'responds 403 Forbidden when the user is not the school-teacher for the class' do
    teacher_id = SecureRandom.uuid
    stub_user_info_api_for_unknown_users(user_id: teacher_id)
    authenticate_as_school_teacher
    school_class.update!(teacher_id:)

    delete("/api/schools/#{school.id}/classes/#{school_class.id}/members/#{class_member.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end
  # rubocop:enable RSpec/ExampleLength

  it 'responds 403 Forbidden when the user is a school-student' do
    authenticate_as_school_student

    delete("/api/schools/#{school.id}/classes/#{school_class.id}/members/#{class_member.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
