# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolStudent::CreateBatch, type: :unit do
  let(:token) { UserProfileMock::TOKEN }
  let(:school) { create(:verified_school) }
  let(:user_id) { create(:teacher, school:).id }

  let(:school_students_params) do
    [
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
  end

  context 'when queuing a job' do
    before do
      stub_profile_api_create_school_students(user_ids: [SecureRandom.uuid, SecureRandom.uuid])
    end

    it 'queues CreateStudentsJob' do
      expect do
        described_class.call(school:, school_students_params:, token:, user_id:)
      end.to have_enqueued_job(CreateStudentsJob).with(school_id: school.id, students: school_students_params, token:)
    end
  end

  context 'when a job has been queued' do
    before do
      stub_profile_api_create_school_students(user_ids: [SecureRandom.uuid, SecureRandom.uuid])
      allow(CreateStudentsJob).to receive(:attempt_perform_later).and_return(
        instance_double(CreateStudentsJob, job_id: SecureRandom.uuid)
      )
    end

    it 'returns a successful operation response' do
      response = described_class.call(school:, school_students_params:, token:, user_id:)
      expect(response.success?).to be(true)
    end

    it 'returns the job id' do
      response = described_class.call(school:, school_students_params:, token:, user_id:)
      expect(response[:job_id]).to be_truthy
    end
  end
end
