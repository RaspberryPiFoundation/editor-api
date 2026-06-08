# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project do
  describe 'salesforce sync' do
    include ActiveJob::TestHelper

    let(:teacher) { create(:teacher, school:) }
    let(:student) { create(:student, school:) }
    let(:school) { create(:school) }
    let(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
    let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id) }

    before do
      stub_user_info_api_for_users([teacher.id, student.id], users: [teacher, student])
      create(:class_student, school_class:, student_id: student.id)
    end

    around do |example|
      ClimateControl.modify(SALESFORCE_ENABLED: 'true') { example.run }
    end

    it 'enqueues Salesforce::LessonSyncJob when a remix of a lesson project is created' do
      lesson_project = lesson.project
      clear_enqueued_jobs

      expect do
        create(:project, school:, user_id: student.id, remixed_from_id: lesson_project.id, lesson:)
      end.to have_enqueued_job(Salesforce::LessonSyncJob).with(lesson_id: lesson.id)
    end

    it 'does not enqueue Salesforce::LessonSyncJob when a project has no parent' do
      clear_enqueued_jobs

      expect { create(:project, user_id: student.id) }
        .not_to have_enqueued_job(Salesforce::LessonSyncJob)
    end

    it 'does not enqueue Salesforce::LessonSyncJob when the remix parent is not a lesson project' do
      standalone_parent = create(:project, user_id: teacher.id)
      clear_enqueued_jobs

      expect do
        create(:project, user_id: student.id, remixed_from_id: standalone_parent.id)
      end.not_to have_enqueued_job(Salesforce::LessonSyncJob)
    end

    context 'when SALESFORCE_ENABLED is false' do
      around do |example|
        ClimateControl.modify(SALESFORCE_ENABLED: 'false') { example.run }
      end

      it 'does not enqueue Salesforce::LessonSyncJob on remix create' do
        lesson_project = lesson.project
        clear_enqueued_jobs

        expect do
          create(:project, school:, user_id: student.id, remixed_from_id: lesson_project.id, lesson:)
        end.not_to have_enqueued_job(Salesforce::LessonSyncJob)
      end
    end
  end
end
