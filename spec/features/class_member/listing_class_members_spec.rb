# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing class members', type: :request do
  before do
    authenticate_as_school_owner
    stub_user_info_api
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:class_member) { create(:class_member) }
  let(:school_class) { class_member.school_class }
  let(:school) { school_class.school }
  let(:student_index) { user_index_by_role('school-student') }
  let(:student_id) { user_id_by_index(student_index) }

  it 'responds 200 OK' do
    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the class members JSON' do
    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:student_id]).to eq(student_id)
  end

  it 'responds with the students JSON' do
    stub_user_info_api_for_student
    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:student_name]).to eq('School Student')
  end

  it "responds with nil attributes for students if the user profile doesn't exist" do
    class_member.update!(student_id: SecureRandom.uuid)

    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:student_name]).to be_nil
  end

  it 'does not include class members that belong to a different class' do
    different_class = create(:school_class, school:)
    create(:class_member, school_class: different_class, student_id: SecureRandom.uuid)

    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(1)
  end

  it 'responds 401 Unauthorized when no token is given' do
    get "/api/schools/#{school.id}/classes/#{school_class.id}/members"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school = create(:school, id: SecureRandom.uuid)
    school_class.update!(school_id: school.id)

    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is not the school-teacher for the class' do
    authenticate_as_school_teacher
    school_class.update!(teacher_id: SecureRandom.uuid)

    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    authenticate_as_school_student

    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
