# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing school classes', type: :request, skip: true do
  before do
    authenticated_in_hydra_as(owner)
    stub_user_info_api_for(teacher)

    create(:class_student, school_class:, student_id: student.id)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:school_class) { create(:school_class, name: 'Test School Class', teacher_ids: [teacher.id], school:) }
  let(:school) { create(:school) }
  let(:student) { create(:student, school:) }
  let(:teacher) { create(:teacher, school:, name: 'School Teacher') }
  let(:owner) { create(:owner, school:) }

  let(:owner_teacher) { create(:teacher, school:, id: owner.id, name: owner.name, email: owner.email) }
  let!(:owner_school_class) { create(:school_class, name: 'Owner School Class', teacher_ids: [owner_teacher.id], school:) }

  it 'responds 200 OK' do
    get("/api/schools/#{school.id}/classes", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the school classes JSON' do
    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:name]).to eq('Test School Class')
  end

  it 'only responds with the user\'s classes if the my_classes param is present' do
    get("/api/schools/#{school.id}/classes?my_classes=true", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:name]).to eq(owner_school_class.name)
  end

  it 'responds with the teachers JSON' do
    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:teacher_name]).to eq('School Teacher')
  end

  it "responds with nil attributes for teachers if the user profile doesn't exist" do
    stub_user_info_api_for_unknown_users(user_id: teacher.id)

    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:teacher_name]).to be_nil
  end

  it "does not include school classes that the school-teacher doesn't teach" do
    teacher = create(:teacher, school:)
    authenticated_in_hydra_as(teacher)
    create(:school_class, school:, teacher_ids: [teacher.id])

    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(1)
  end

  it "does not include school classes that the school-student isn't a member of" do
    teacher = create(:teacher, school:)
    authenticated_in_hydra_as(student)
    create(:school_class, school:, teacher_ids: [teacher.id])

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
