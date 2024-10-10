# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolStudent::CreateBatch, type: :unit do
  let(:token) { UserProfileMock::TOKEN }
  let(:school) { create(:verified_school) }
  let(:user_id) { SecureRandom.uuid }
  let(:user_id_2) { SecureRandom.uuid }

  let(:school_student_params) do
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
    stub_profile_api_create_school_students(user_ids: [user_id, user_id_2])
    ActiveJob::Base.queue_adapter = :test
  end

  it 'returns a successful operation response' do
    response = described_class.call(school:, school_student_params:, token:)
    expect(response.success?).to be(true)
  end

  it 'queues CreateStudentsJob' do
    expect do
      described_class.call(school:, school_student_params:, token:)
    end.to have_enqueued_job(CreateStudentsJob).with(school_id: school.id, students: school_student_params, token:)
  end

  context 'when validation fails' do
    let(:school_student_params) do
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
        described_class.call(school:, school_student_params:, token:)
      end.not_to have_enqueued_job(CreateStudentsJob)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school:, school_student_params:, token:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, school_student_params:, token:)
      error_message = response[:error].message
      expect(error_message).to match(/Error creating student 1: username '' is invalid/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school:, school_student_params:, token:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
