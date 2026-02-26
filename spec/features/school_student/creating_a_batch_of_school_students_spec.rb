# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a batch of school students', type: :request do
  before do
    authenticated_in_hydra_as(owner)
    stub_profile_api_create_school_students
    stub_profile_api_validate_school_students
    stub_profile_api_create_safeguarding_flag

    # UserJob will fail validation as it won't find our test job, so we need to double it
    allow(CreateStudentsJob).to receive(:attempt_perform_later).and_return(
      instance_double(CreateStudentsJob, job_id: SecureRandom.uuid)
    )
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:verified_school) }
  let(:student_id) { SecureRandom.uuid }
  let(:owner) { create(:owner, school:) }

  let(:params) do
    {
      school_students: [
        {
          username: 'student-to-create',
          password: 'SaoXlDBAyiAFoMH3VsddhdA7JWnM8P8by1wOjBUWH2g=',
          name: 'School Student'
        },
        {
          username: 'second-student-to-create',
          password: 'SaoXlDBAyiAFoMH3VsddhdA7JWnM8P8by1wOjBUWH2g=',
          name: 'School Student 2'
        }
      ]
    }
  end

  let(:bad_params) do
    {
      school_students: [
        {
          username: 'student-to-create',
          password: 'Password',
          name: 'School Student'
        },
        {
          username: 'second-student-to-create',
          password: 'Password',
          name: 'School Student 2'
        }
      ]
    }
  end

  it 'creates the school owner safeguarding flag' do
    post("/api/schools/#{school.id}/students/batch", headers:, params:)
    expect(ProfileApiClient).to have_received(:create_safeguarding_flag).with(token: UserProfileMock::TOKEN, flag: ProfileApiClient::SAFEGUARDING_FLAGS[:owner], email: owner.email, school_id: school.id)
  end

  it 'does not create the school teacher safeguarding flag' do
    post("/api/schools/#{school.id}/students/batch", headers:, params:)
    expect(ProfileApiClient).not_to have_received(:create_safeguarding_flag).with(token: UserProfileMock::TOKEN, flag: ProfileApiClient::SAFEGUARDING_FLAGS[:teacher], email: owner.email, school_id: school.id)
  end

  it 'responds 202 Accepted' do
    post("/api/schools/#{school.id}/students/batch", headers:, params:)
    expect(response).to have_http_status(:accepted)
  end

  it 'responds 422 when a batch already exists for this school' do
    # Create a fake batch for the school.
    GoodJob::BatchRecord.create!(
      description: school.id,
      finished_at: nil,
      discarded_at: nil
    )

    expect do
      post("/api/schools/#{school.id}/students/batch", headers:, params:)
    end.not_to change(GoodJob::BatchRecord, :count)
    expect(response).to have_http_status(:unprocessable_entity)

    active_batches = GoodJob::BatchRecord.where(
      description: school.id,
      finished_at: nil,
      discarded_at: nil
    )
    expect(active_batches.count).to eq(1)
  end

  it 'responds 202 Accepted when the user is a school-teacher' do
    teacher = create(:teacher, school:)
    authenticated_in_hydra_as(teacher)

    post("/api/schools/#{school.id}/students/batch", headers:, params:)
    expect(response).to have_http_status(:accepted)
  end

  it 'splits students into jobs of 50 each' do
    total_students = 169
    students = Array.new(total_students) do |i|
      { username: "student-#{i}", password: 'SaoXlDBAyiAFoMH3VsddhdA7JWnM8P8by1wOjBUWH2g=', name: "Student #{i}" }
    end

    post("/api/schools/#{school.id}/students/batch", headers:, params: { school_students: students })
    expect(CreateStudentsJob).to have_received(:attempt_perform_later).exactly((total_students.to_f / 50).ceil).times
  end

  it 'does not create the school owner safeguarding flag when the user is a school-teacher' do
    teacher = create(:teacher, school:)
    authenticated_in_hydra_as(teacher)

    post("/api/schools/#{school.id}/students/batch", headers:, params:)
    expect(ProfileApiClient).not_to have_received(:create_safeguarding_flag).with(token: UserProfileMock::TOKEN, flag: ProfileApiClient::SAFEGUARDING_FLAGS[:owner], email: owner.email, school_id: school.id)
  end

  it 'creates the school teacher safeguarding flag when the user is a school-teacher' do
    teacher = create(:teacher, school:)
    authenticated_in_hydra_as(teacher)

    post("/api/schools/#{school.id}/students/batch", headers:, params:)
    expect(ProfileApiClient).to have_received(:create_safeguarding_flag).with(token: UserProfileMock::TOKEN, flag: ProfileApiClient::SAFEGUARDING_FLAGS[:teacher], email: teacher.email, school_id: school.id)
  end

  it 'responds 422 Unprocessable Entity when params are invalid' do
    post("/api/schools/#{school.id}/students/batch", headers:, params: { school_students: [] })
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'responds 422 Unprocessable Entity with a suitable message when params are invalid' do
    post("/api/schools/#{school.id}/students/batch", headers:, params: bad_params)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include('Decryption failed: iv must be 16 bytes')
  end

  it 'responds 422 Unprocessable Entity with a JSON array of validation errors' do
    stub_profile_api_create_school_students_validation_error
    stub_profile_api_validate_students_with_validation_error
    post("/api/schools/#{school.id}/students/batch", headers:, params:)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to eq(
      {
        error: {
          'student-to-create' => %w[isUniqueInBatch isComplex notEmpty],
          'another-student-to-create-2' => %w[minLength notEmpty]
        },
        error_type: 'validation_error'
      }.to_json
    )
  end

  it 'responds 401 Unauthorized when no token is given' do
    post("/api/schools/#{school.id}/students/batch", params:)
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    Role.owner.find_by(user_id: owner.id, school:).delete
    school.update!(id: SecureRandom.uuid)

    post("/api/schools/#{school.id}/students/batch", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    student = create(:student, school:)
    authenticated_in_hydra_as(student)

    post("/api/schools/#{school.id}/students/batch", headers:, params:)
    expect(response).to have_http_status(:forbidden)
  end
end
