# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salesforce::LessonSyncJob, :requires_salesforce_db do
  include ActiveSupport::Testing::TimeHelpers

  subject(:perform_job) { described_class.perform_now(lesson_id: lesson.id) }

  let(:teacher) { create(:teacher, school:) }
  let(:school) { create(:school) }
  let(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
  let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id) }
  let!(:sf_school_class) do
    next if lesson.school_class_id.blank?

    create(:salesforce_school_class, classroomuuid__c: lesson.school_class_id, sfid: SecureRandom.alphanumeric(18))
  end

  around do |example|
    ClimateControl.modify(SALESFORCE_ENABLED: 'true') { example.run }
  end

  context 'when the job has run' do
    before { perform_job }

    it 'syncs all FIELD_MAPPINGS to the correct lesson values' do
      sf_lesson = Salesforce::Lesson.find_by(lesson_uuid__c: lesson.id)
      described_class::FIELD_MAPPINGS.each do |sf_field, lesson_field|
        expected = Salesforce::Lesson.type_for_attribute(sf_field).cast(lesson.send(lesson_field))
        expect(sf_lesson.send(sf_field)).to eq(expected)
      end
    end

    it 'syncs teacherprojecttitle__c from the lesson project name' do
      sf_lesson = Salesforce::Lesson.find_by(lesson_uuid__c: lesson.id)
      expect(sf_lesson.teacherprojecttitle__c).to eq(lesson.project.name)
    end

    it 'syncs teacherprojecttype__c from the lesson project type' do
      sf_lesson = Salesforce::Lesson.find_by(lesson_uuid__c: lesson.id)
      expect(sf_lesson.teacherprojecttype__c).to eq(lesson.project.project_type)
    end
  end

  describe 'numberofassignedprojects__c' do
    let(:students) { Array.new(3) { create(:student, school:) } }

    before do
      students.each { |s| create(:class_student, school_class:, student_id: s.id) }
    end

    it 'syncs the class student count when visibility is students' do
      lesson.update!(visibility: 'students')
      perform_job
      sf_lesson = Salesforce::Lesson.find_by(lesson_uuid__c: lesson.id)
      expect(sf_lesson.numberofassignedprojects__c).to eq(3)
    end

    it 'syncs zero when visibility is teachers' do
      lesson.update!(visibility: 'teachers')
      perform_job
      sf_lesson = Salesforce::Lesson.find_by(lesson_uuid__c: lesson.id)
      expect(sf_lesson.numberofassignedprojects__c).to eq(0)
    end

    it 'syncs zero when visibility is private' do
      lesson.update!(visibility: 'private')
      perform_job
      sf_lesson = Salesforce::Lesson.find_by(lesson_uuid__c: lesson.id)
      expect(sf_lesson.numberofassignedprojects__c).to eq(0)
    end

    it 'syncs zero when visibility is public' do
      lesson.update!(visibility: 'public')
      perform_job
      sf_lesson = Salesforce::Lesson.find_by(lesson_uuid__c: lesson.id)
      expect(sf_lesson.numberofassignedprojects__c).to eq(0)
    end
  end

  describe 'numberofcompletedprojects__c' do
    let(:student) { create(:student, school:) }

    it 'syncs the cached submitted_projects_count when there are no Experience CS finishes' do
      lesson.update!(submitted_projects_count: 7)
      perform_job
      sf_lesson = Salesforce::Lesson.find_by(lesson_uuid__c: lesson.id)
      expect(sf_lesson.numberofcompletedprojects__c).to eq(7)
    end

    it 'syncs the Experience CS finished count when there are no state-machine submissions' do
      finished_remix = create(:project, school:, user_id: student.id, remixed_from_id: lesson.project.id)
      finished_remix.school_project.update!(finished: true)
      perform_job
      sf_lesson = Salesforce::Lesson.find_by(lesson_uuid__c: lesson.id)
      expect(sf_lesson.numberofcompletedprojects__c).to eq(1)
    end

    it 'sums state-machine submissions and Experience CS finishes' do
      lesson.update!(submitted_projects_count: 4)
      2.times do
        finished_remix = create(:project, school:, user_id: student.id, remixed_from_id: lesson.project.id)
        finished_remix.school_project.update!(finished: true)
      end
      perform_job
      sf_lesson = Salesforce::Lesson.find_by(lesson_uuid__c: lesson.id)
      expect(sf_lesson.numberofcompletedprojects__c).to eq(6)
    end
  end

  context 'when the lesson has no project' do
    let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id, project: nil) }

    before { perform_job }

    it 'leaves teacherprojecttitle__c nil' do
      sf_lesson = Salesforce::Lesson.find_by(lesson_uuid__c: lesson.id)
      expect(sf_lesson.teacherprojecttitle__c).to be_nil
    end

    it 'leaves teacherprojecttype__c nil' do
      sf_lesson = Salesforce::Lesson.find_by(lesson_uuid__c: lesson.id)
      expect(sf_lesson.teacherprojecttype__c).to be_nil
    end
  end

  context 'when syncing lastsyncdate__c' do
    it 'sets lastsyncdate__c to the time the job ran' do
      freeze_time do
        perform_job
        sf_lesson = Salesforce::Lesson.find_by(lesson_uuid__c: lesson.id)
        expect(sf_lesson.lastsyncdate__c).to eq(Time.current)
      end
    end
  end

  context 'when the lesson has no school class' do
    let(:lesson) { create(:lesson, school:, user_id: teacher.id) }

    it 'does not create a Salesforce lesson record' do
      perform_job
      expect(Salesforce::Lesson.find_by(lesson_uuid__c: lesson.id)).to be_nil
    end
  end

  context 'when the parent Classroom__c is not yet synced to Salesforce' do
    before { sf_school_class.update!(sfid: nil) }

    it 'retries the job to defer the lesson write' do
      expect { perform_job }.to have_enqueued_job(described_class).with(lesson_id: lesson.id)
    end

    it 'does not write the lesson to the mirror' do
      perform_job
      expect(Salesforce::Lesson.find_by(lesson_uuid__c: lesson.id)).to be_nil
    end
  end

  context 'when there is no Salesforce::SchoolClass row for the lesson' do
    before { sf_school_class.destroy }

    it 'retries the job' do
      expect { perform_job }.to have_enqueued_job(described_class).with(lesson_id: lesson.id)
    end

    it 'does not write the lesson to the mirror' do
      perform_job
      expect(Salesforce::Lesson.find_by(lesson_uuid__c: lesson.id)).to be_nil
    end
  end

  context 'when the Salesforce lesson fails to save' do
    let(:sf_lesson) { instance_double(Salesforce::Lesson) }

    before do
      allow(Salesforce::Lesson).to receive(:find_or_initialize_by)
        .with(lesson_uuid__c: lesson.id).and_return(sf_lesson)
      allow(sf_lesson).to receive(:attributes=)
      allow(sf_lesson).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
    end

    it 'raises an error' do
      expect { perform_job }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  context 'when SALESFORCE_ENABLED is false' do
    around do |example|
      ClimateControl.modify(SALESFORCE_ENABLED: 'false') { example.run }
    end

    it 'discards the job without syncing' do
      perform_job
      expect(Salesforce::Lesson.find_by(lesson_uuid__c: lesson.id)).to be_nil
    end
  end

  describe '#concurrency_key_id' do
    it 'returns the lesson_id' do
      job = described_class.new(lesson_id: lesson.id)
      expect(job.send(:concurrency_key_id)).to eq(lesson.id)
    end
  end
end
