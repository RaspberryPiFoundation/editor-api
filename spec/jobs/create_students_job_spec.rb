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
      password: 'SaoXlDBAyiAFoMH3VsddhdA7JWnM8P8by1wOjBUWH2g=',
      name: 'School Student'
    }]
  end

  around do |example|
    original = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :good_job
    example.run
  ensure
    ActiveJob::Base.queue_adapter = original
  end

  before do
    stub_profile_api_create_school_students(user_ids: [user_id])
  end

  after do
    GoodJob::Job.delete_all
  end

  it 'calls ProfileApiClient' do
    described_class.perform_now(school_id: school.id, students:, token:)

    expect(ProfileApiClient).to have_received(:create_school_students)
      .with(token:, students: [{ username: 'student-to-create', password: 'Student2024', name: 'School Student' }], school_id: school.id)
  end

  it 'creates a new student role' do
    described_class.perform_now(school_id: school.id, students:, token:)

    expect(Role.student.where(school:, user_id:)).to exist
  end
end
