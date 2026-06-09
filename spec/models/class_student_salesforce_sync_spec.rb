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

    it 'enqueues a classroom sync when a student joins a class' do
      clear_enqueued_jobs

      expect { create(:class_student, school_class:, student_id: student.id) }
        .to have_enqueued_job(Salesforce::SchoolClassSyncJob).with(school_class_id: school_class.id)
    end

    it 'enqueues a lesson sync for each visible-to-students lesson when a student joins' do
      visible_lesson = create(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'students')
      clear_enqueued_jobs

      expect { create(:class_student, school_class:, student_id: student.id) }
        .to have_enqueued_job(Salesforce::LessonSyncJob).with(lesson_id: visible_lesson.id)
    end

    it 'does not enqueue a lesson sync for lessons that are not visible to students' do
      create(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'teachers')
      clear_enqueued_jobs

      expect { create(:class_student, school_class:, student_id: student.id) }
        .not_to have_enqueued_job(Salesforce::LessonSyncJob)
    end

    it 'enqueues a lesson sync for each visible-to-students lesson when a student leaves' do
      class_student = create(:class_student, school_class:, student_id: student.id)
      visible_lesson = create(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'students')
      clear_enqueued_jobs

      expect { class_student.destroy! }
        .to have_enqueued_job(Salesforce::LessonSyncJob).with(lesson_id: visible_lesson.id)
    end

    it 'does not raise when destroyed via cascade after the parent SchoolClass is gone' do
      create(:class_student, school_class:, student_id: student.id)
      create(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'students')

      expect { school_class.destroy! }.not_to raise_error
    end
  end
end
