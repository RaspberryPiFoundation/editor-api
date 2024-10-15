# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateStudentsJob do
  include ActiveJob::TestHelper

  let(:token) { UserProfileMock::TOKEN }
  let(:school) { create(:verified_school) }
  let(:user_id) { create(:user).id }

  let(:students) do
    [{
      username: 'student-to-create',
      password: 'at-least-8-characters',
      name: 'School Student'
    }]
  end

  before do
    ActiveJob::Base.queue_adapter = :good_job

    stub_profile_api_create_school_students(user_ids: [user_id])
  end

  after do
    GoodJob::Job.delete_all

    ActiveJob::Base.queue_adapter = :test
  end

  it 'calls ProfileApiClient' do
    described_class.perform_now(school_id: school.id, students:, token:)

    expect(ProfileApiClient).to have_received(:create_school_students)
      .with(token:, students: [{ username: 'student-to-create', password: 'at-least-8-characters', name: 'School Student' }], school_id: school.id)
  end

  it 'creates a new student role' do
    described_class.perform_now(school_id: school.id, students:, token:)

    expect(Role.student.where(school:, user_id:)).to exist
  end

  it 'does not enqueue a job if one is already running for that school' do
    # Enqueue the job
    GoodJob::Job.enqueue(described_class.new(school_id: school.id, students:, token:))

    expect do
      described_class.attempt_perform_later(school_id: school.id, students:, token:)
    end.to raise_error(ConcurrencyExceededForSchool)
  end
end
