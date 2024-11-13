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

  before do
    ActiveJob::Base.queue_adapter = :test
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

  context 'when a normal error occurs' do
    let(:school_students_params) do
      [
        {
          username: 'a-student',
          password: 'Password',
          name: 'School Student'
        },
        {
          username: 'second-student-to-create',
          password: 'Password',
          name: 'School Student 2'
        }
      ]
    end

    before do
      stub_profile_api_create_school_students(user_ids: [SecureRandom.uuid, SecureRandom.uuid])
      allow(Sentry).to receive(:capture_exception)
    end

    it 'does not queue a new job' do
      expect do
        described_class.call(school:, school_students_params:, token:, user_id:)
      end.not_to have_enqueued_job(CreateStudentsJob)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school:, school_students_params:, token:, user_id:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, school_students_params:, token:, user_id:)
      error_message = response[:error]
      expect(error_message).to match(/Error creating school students: Decryption failed: iv must be 16 bytes/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school:, school_students_params:, token:, user_id:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end

  context 'when a validation error occurs' do
    before do
      stub_profile_api_create_school_students_validation_error
    end

    it 'returns the expected formatted errors' do
      response = described_class.call(school:, school_students_params:, token:, user_id:)
      expect(response[:error]).to eq(
        { 'student-to-create' => ['Username must be unique in the batch data', 'Password is too simple (it should not be easily guessable, <a href="https://my.raspberrypi.org/password-help">need password help?</a>)', 'You must supply a name'], 'another-student-to-create-2' => ['Password must be at least 8 characters', 'You must supply a name'] }
      )
    end
  end
end
