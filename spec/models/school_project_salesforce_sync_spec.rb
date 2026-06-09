# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolProject do
  describe 'salesforce sync on finished change' do
    include ActiveJob::TestHelper

    let(:teacher) { create(:teacher, school:) }
    let(:student) { create(:student, school:) }
    let(:school) { create(:school) }
    let(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
    let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id) }
    let(:remix) { create(:project, school:, user_id: student.id, remixed_from_id: lesson.project.id) }
    let(:school_project) { remix.school_project }

    before do
      stub_user_info_api_for_users([teacher.id, student.id], users: [teacher, student])
      create(:class_student, school_class:, student_id: student.id)
    end

    around do |example|
      ClimateControl.modify(SALESFORCE_ENABLED: 'true') { example.run }
    end

    it 'enqueues Salesforce::LessonSyncJob when finished flips to true' do
      school_project
      clear_enqueued_jobs

      expect { school_project.update!(finished: true) }
        .to have_enqueued_job(Salesforce::LessonSyncJob).with(lesson_id: lesson.id)
    end

    it 'enqueues Salesforce::LessonSyncJob again when finished flips back to false' do
      school_project.update!(finished: true)
      clear_enqueued_jobs

      expect { school_project.update!(finished: false) }
        .to have_enqueued_job(Salesforce::LessonSyncJob).with(lesson_id: lesson.id)
    end

    it 'does not enqueue Salesforce::LessonSyncJob when finished is unchanged' do
      school_project.update!(finished: true)
      clear_enqueued_jobs

      expect { school_project.update!(updated_at: 1.minute.from_now) }
        .not_to have_enqueued_job(Salesforce::LessonSyncJob)
    end

    context 'when SALESFORCE_ENABLED is false' do
      around do |example|
        ClimateControl.modify(SALESFORCE_ENABLED: 'false') { example.run }
      end

      it 'does not enqueue Salesforce::LessonSyncJob' do
        school_project
        clear_enqueued_jobs

        expect { school_project.update!(finished: true) }
          .not_to have_enqueued_job(Salesforce::LessonSyncJob)
      end
    end
  end

  describe 'salesforce sync on state transitions' do
    include ActiveJob::TestHelper

    let(:teacher) { create(:teacher, school:) }
    let(:student) { create(:student, school:) }
    let(:school) { create(:school) }
    let(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
    let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id) }
    let(:remix) { create(:project, school:, user_id: student.id, remixed_from_id: lesson.project.id) }
    let(:school_project) { remix.school_project }

    before do
      stub_user_info_api_for_users([teacher.id, student.id], users: [teacher, student])
      create(:class_student, school_class:, student_id: student.id)
      school_project
      clear_enqueued_jobs
    end

    around do |example|
      ClimateControl.modify(SALESFORCE_ENABLED: 'true') { example.run }
    end

    it 'enqueues Salesforce::LessonSyncJob exactly once on transition to :submitted' do
      expect { school_project.transition_status_to!(:submitted, teacher.id) }
        .to have_enqueued_job(Salesforce::LessonSyncJob).with(lesson_id: lesson.id).exactly(:once)
    end

    it 'enqueues Salesforce::LessonSyncJob exactly once on transition from :submitted' do
      school_project.transition_status_to!(:submitted, teacher.id)
      clear_enqueued_jobs

      expect { school_project.transition_status_to!(:complete, teacher.id) }
        .to have_enqueued_job(Salesforce::LessonSyncJob).with(lesson_id: lesson.id).exactly(:once)
    end

    it 'does not enqueue Salesforce::LessonSyncJob when transitioning unsubmitted → complete' do
      expect { school_project.transition_status_to!(:complete, teacher.id) }
        .not_to have_enqueued_job(Salesforce::LessonSyncJob)
    end

    it 'does not enqueue Salesforce::LessonSyncJob when transitioning complete → unsubmitted' do
      school_project.transition_status_to!(:complete, teacher.id)
      clear_enqueued_jobs

      expect { school_project.transition_status_to!(:unsubmitted, teacher.id) }
        .not_to have_enqueued_job(Salesforce::LessonSyncJob)
    end
  end
end
