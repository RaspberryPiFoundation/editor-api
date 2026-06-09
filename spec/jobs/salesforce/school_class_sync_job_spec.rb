# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salesforce::SchoolClassSyncJob, :requires_salesforce_db do
  include ActiveSupport::Testing::TimeHelpers

  subject(:perform_job) { described_class.perform_now(school_class_id: school_class.id) }

  let(:teacher) { create(:teacher, school:) }
  let(:school) { create(:school) }
  let(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
  let!(:sf_school) do
    create(:salesforce_school, editoruuid__c: school_class.school_id, sfid: SecureRandom.alphanumeric(18))
  end

  around do |example|
    ClimateControl.modify(SALESFORCE_ENABLED: 'true') { example.run }
  end

  context 'when the job has run' do
    before { perform_job }

    it 'syncs all FIELD_MAPPINGS to the correct school class values' do
      sf_school_class = Salesforce::SchoolClass.find_by(classroomuuid__c: school_class.id)
      described_class::FIELD_MAPPINGS.each do |sf_field, school_class_field|
        expected = Salesforce::SchoolClass.type_for_attribute(sf_field).cast(school_class.send(school_class_field))
        expect(sf_school_class.send(sf_field)).to eq(expected)
      end
    end
  end

  context 'when there is a student in the school class' do
    before do
      student = create(:student, school:)
      create(:class_student, school_class:, student_id: student.id)
      perform_job
    end

    it 'syncs numberofmembers__c from class students' do
      sf_school_class = Salesforce::SchoolClass.find_by(classroomuuid__c: school_class.id)
      expect(sf_school_class.numberofmembers__c).to eq(1)
    end
  end

  context 'when syncing lastsyncdate__c' do
    it 'sets lastsyncdate__c to the time the job ran' do
      freeze_time do
        perform_job
        sf_school_class = Salesforce::SchoolClass.find_by(classroomuuid__c: school_class.id)
        expect(sf_school_class.lastsyncdate__c).to eq(Time.current)
      end
    end
  end

  context 'when the parent Editor__c is not yet synced to Salesforce' do
    before { sf_school.update!(sfid: nil) }

    it 'retries the job to defer the school class write' do
      expect { perform_job }.to have_enqueued_job(described_class).with(school_class_id: school_class.id)
    end

    it 'does not write the school class to the mirror' do
      perform_job
      expect(Salesforce::SchoolClass.find_by(classroomuuid__c: school_class.id)).to be_nil
    end
  end

  context 'when there is no Salesforce::School row for the school class' do
    before { sf_school.destroy }

    it 'retries the job' do
      expect { perform_job }.to have_enqueued_job(described_class).with(school_class_id: school_class.id)
    end

    it 'does not write the school class to the mirror' do
      perform_job
      expect(Salesforce::SchoolClass.find_by(classroomuuid__c: school_class.id)).to be_nil
    end
  end

  context 'when the Salesforce school class fails to save' do
    let(:sf_school_class) { instance_double(Salesforce::SchoolClass) }

    before do
      allow(Salesforce::SchoolClass).to receive(:find_or_initialize_by)
        .with(classroomuuid__c: school_class.id).and_return(sf_school_class)
      allow(sf_school_class).to receive(:attributes=)
      allow(sf_school_class).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
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
      expect(Salesforce::SchoolClass.find_by(classroomuuid__c: school_class.id)).to be_nil
    end
  end

  describe '#concurrency_key_id' do
    it 'returns the school_class_id' do
      job = described_class.new(school_class_id: school_class.id)
      expect(job.send(:concurrency_key_id)).to eq(school_class.id)
    end
  end
end
