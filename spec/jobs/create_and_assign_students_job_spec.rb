# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateAndAssignStudentsJob do
  let(:school) { create(:verified_school) }
  let(:current_user) { create(:teacher, school:, token: UserProfileMock::TOKEN) }
  let(:school_class) { create(:school_class, school:, teacher_ids: [current_user.id]) }
  let(:student_ids) { [SecureRandom.uuid, SecureRandom.uuid] }

  let(:students) do
    [
      { name: 'Jane Student', email: 'jane.student@example.com' },
      { name: 'John Student', email: 'john.student@example.com' }
    ]
  end

  before do
    stub_profile_api_create_safeguarding_flag
    stub_profile_api_create_school_students_sso(user_ids: student_ids)
  end

  after do
    GoodJob::Job.delete_all
  end

  describe '#perform' do
    it 'creates the students in Profile' do
      described_class.perform_now(school_class_id: school_class.id, students:, creator_id: current_user.id, token: current_user.token)

      expect(ProfileApiClient).to have_received(:create_school_students_sso)
        .with(token: current_user.token, students:, school_id: school.id)
    end

    it 'gives the students a role in the school and adds them to the class' do
      described_class.perform_now(school_class_id: school_class.id, students:, creator_id: current_user.id, token: current_user.token)

      expect(Role.student.where(school:, user_id: student_ids).count).to eq(2)
      expect(school_class.students.pluck(:student_id)).to match_array(student_ids)
    end

    it 'reports students that could not be created to Sentry' do
      allow(ProfileApiClient).to receive(:create_school_students_sso)
        .and_return([{ name: 'Jane Student', success: false, error: 'unknown error' }])
      allow(Sentry).to receive(:capture_message)

      described_class.perform_now(school_class_id: school_class.id, students:, creator_id: current_user.id, token: current_user.token)

      expect(Sentry).to have_received(:capture_message)
        .with('Student creation failed in Profile', extra: 'unknown error')
    end
  end

  describe 'concurrency' do
    it 'allows only one job to perform at a time per school class' do
      job = described_class.new(school_class_id: school_class.id, students:, creator_id: current_user.id, token: current_user.token)

      expect(job.good_job_labels).to eq(["create-and-assign-students-school-#{school_class.id}"])
      expect(described_class.good_job_concurrency_rules.first.perform_limit).to eq(1)
    end
  end

  describe '.enqueue_batches' do
    it 'creates a safeguarding flag for the user' do
      described_class.enqueue_batches(school_class:, students:, current_user:)

      expect(ProfileApiClient).to have_received(:create_safeguarding_flag)
        .with(token: current_user.token, flag: 'school:teacher', email: current_user.email, school_id: school.id)
    end

    it 'records the batch against the user' do
      batch = described_class.enqueue_batches(school_class:, students:, current_user:)

      expect(UserJob.find_by(user_id: current_user.id)).to have_attributes(good_job_batch_id: batch.id)
    end
  end
end
