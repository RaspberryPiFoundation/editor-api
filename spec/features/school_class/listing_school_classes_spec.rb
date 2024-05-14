# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing school classes', type: :request do
  before do
    authenticate_as_school_owner
    stub_user_info_api
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:school_class) { create(:school_class, name: 'Test School Class') }
  let(:school) { school_class.school }
  let!(:member) { create(:class_member, school_class:) }

  it 'responds 200 OK' do
    get("/api/schools/#{school.id}/classes", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the school classes JSON' do
    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:name]).to eq('Test School Class')
  end

  it 'responds with the teachers JSON' do
    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:teacher_name]).to eq('School Teacher')
  end

  it "responds with nil attributes for teachers if the user profile doesn't exist" do
    school_class.update!(teacher_id: SecureRandom.uuid)

    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:teacher_name]).to be_nil
  end

  it "does not include school classes that the school-teacher doesn't teach" do
    authenticate_as_school_teacher
    create(:school_class, school:, teacher_id: SecureRandom.uuid)

    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(1)
  end

  it "does not include school classes that the school-student isn't a member of" do
    authenticate_as_school_student(member)

    create(:school_class, school:, teacher_id: SecureRandom.uuid)

    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(1)
  end

  it 'responds 401 Unauthorized when no token is given' do
    get "/api/schools/#{school.id}/classes"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school = create(:school, id: SecureRandom.uuid)
    school_class.update!(school_id: school.id)

    get("/api/schools/#{school.id}/classes/#{school_class.id}/members", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
