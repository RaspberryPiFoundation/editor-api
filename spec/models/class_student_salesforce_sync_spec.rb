# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClassStudent do
  describe 'salesforce sync' do
    include ActiveJob::TestHelper

    before do
      stub_user_info_api_for_users([teacher.id, student.id], users: [teacher, student])
    end

    let(:teacher) { create(:teacher, school:) }
    let(:school) { create(:school) }
    let(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
    let(:student) { create(:student, school:) }

    around do |example|
      ClimateControl.modify(SALESFORCE_ENABLED: 'true') { example.run }
    end

    it 'enqueues a classroom sync but not a lesson sync when a student joins a class' do
      create(:lesson, school:, school_class:, user_id: teacher.id)
      clear_enqueued_jobs

      expect do
        create(:class_student, school_class:, student_id: student.id)
      end.to have_enqueued_job(Salesforce::SchoolClassSyncJob)
        .and(not_have_enqueued_job(Salesforce::LessonSyncJob))
    end
  end
end
