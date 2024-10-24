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
        password: 'at-least-8-characters',
        name: 'School Student'
      },
      {
        username: 'second-student-to-create',
        password: 'at-least-8-characters',
        name: 'School Student 2'
      }
    ]
  end

  before do
    stub_profile_api_create_school_students(user_ids: [SecureRandom.uuid, SecureRandom.uuid])

    ActiveJob::Base.queue_adapter = :test
  end

  it 'queues CreateStudentsJob' do
    expect do
      described_class.call(school:, school_students_params:, token:, user_id:)
    end.to have_enqueued_job(CreateStudentsJob).with(school_id: school.id, students: school_students_params, token:)
  end

  context 'when a job has been queued' do
    before do
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

  context 'when validation fails' do
    let(:school_students_params) do
      [
        {
          username: '',
          password: 'at-least-8-characters',
          name: 'School Student'
        },
        {
          username: 'second-student-to-create',
          password: 'at-least-8-characters',
          name: 'School Student 2'
        }
      ]
    end

    before do
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
      error_message = response[:error].message
      expect(error_message).to match(/Error creating student 1: username '' is invalid/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school:, school_students_params:, token:, user_id:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
