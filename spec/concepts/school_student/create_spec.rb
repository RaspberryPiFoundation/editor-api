# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolStudent::Create, type: :unit do
  let(:token) { UserProfileMock::TOKEN }
  let(:school) { create(:verified_school) }
  let(:user_id) { SecureRandom.uuid }

  let(:school_student_params) do
    {
      username: 'student-to-create',
      password: 'at-least-8-characters',
      name: 'School Student'
    }
  end

  before do
    stub_profile_api_create_school_student(user_id:)
    ActiveJob::Base.queue_adapter = :test
  end

  it 'returns a successful operation response' do
    response = described_class.call(school:, school_student_params:, token:)
    expect(response.success?).to be(true)
  end

  it 'queues CreateStudentsJob' do
    expect do
      described_class.call(school:, school_student_params:, token:)
    end.to have_enqueued_job(CreateStudentsJob).with(school_id: school.id, students: [school_student_params], token:)
  end

  context 'when validation fails' do
    let(:school_student_params) do
      {
        username: '',
        password: 'at-least-8-characters',
        name: 'School Student'
      }
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
      expect(response[:error]).to match(/username '' is invalid/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school:, school_student_params:, token:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
