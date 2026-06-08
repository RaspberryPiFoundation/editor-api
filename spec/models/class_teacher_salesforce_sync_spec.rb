# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClassTeacher do
  describe 'salesforce sync' do
    include ActiveJob::TestHelper

    before do
      stub_user_info_api_for_users([teacher.id, another_teacher.id], users: [teacher, another_teacher])
    end

    let(:teacher) { create(:teacher, school:) }
    let(:another_teacher) { create(:teacher, school:) }
    let(:school) { create(:school) }
    let(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }

    around do |example|
      ClimateControl.modify(SALESFORCE_ENABLED: 'true') { example.run }
    end

    it 'enqueues classroom and class-teacher sync jobs when a teacher is added to an existing class' do
      school_class
      clear_enqueued_jobs

      expect { create(:class_teacher, school_class:, teacher_id: another_teacher.id) }
        .to have_enqueued_job(Salesforce::SchoolClassSyncJob)
        .and have_enqueued_job(Salesforce::ClassTeacherSyncJob)
    end

    # SchoolClass + initial ClassTeacher rows commit in the same transaction (via
    # SchoolClass::Create / accepts_nested_attributes_for). Both records' after_commit
    # callbacks enqueue a SchoolClassSyncJob (deduped at execution by the base job's
    # good_job_control_concurrency_with), hence .at_least(:once). The ClassTeacherSyncJob
    # races SchoolClassSyncJob for the parent classroom mirror; ensure_parent_synced! +
    # retry_on cover that race in the job layer (see class_teacher_sync_job_spec).
    it 'enqueues classroom and class-teacher sync jobs for the initial teachers of a brand-new class' do
      clear_enqueued_jobs

      expect { create(:school_class, teacher_ids: [another_teacher.id], school:) }
        .to have_enqueued_job(Salesforce::SchoolClassSyncJob).at_least(:once)
        .and have_enqueued_job(Salesforce::ClassTeacherSyncJob)
    end

    it 'enqueues classroom sync but not class-teacher sync when a class teacher is destroyed' do
      class_teacher = create(:class_teacher, school_class:, teacher_id: another_teacher.id)
      clear_enqueued_jobs

      expect { class_teacher.destroy! }
        .to have_enqueued_job(Salesforce::SchoolClassSyncJob)
        .and(not_have_enqueued_job(Salesforce::ClassTeacherSyncJob))
    end

    context 'when SALESFORCE_ENABLED is false' do
      around do |example|
        ClimateControl.modify(SALESFORCE_ENABLED: 'false') { example.run }
      end

      it 'does not enqueue Salesforce::ClassTeacherSyncJob on create' do
        school_class
        clear_enqueued_jobs

        expect { create(:class_teacher, school_class:, teacher_id: another_teacher.id) }
          .not_to have_enqueued_job(Salesforce::ClassTeacherSyncJob)
      end
    end
  end
end
