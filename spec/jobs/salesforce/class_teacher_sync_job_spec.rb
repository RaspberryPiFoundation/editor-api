# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salesforce::ClassTeacherSyncJob, :requires_salesforce_db do
  subject(:perform_job) { described_class.perform_now(class_teacher_id: class_teacher.id) }

  let(:teacher) { create(:teacher, school:) }
  let(:another_teacher) { create(:teacher, school:) }
  let(:school) { create(:school) }
  let(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
  let(:class_teacher) { create(:class_teacher, school_class:, teacher_id: another_teacher.id) }
  let!(:sf_school_class) do
    create(:salesforce_school_class, classroomuuid__c: class_teacher.school_class_id, sfid: SecureRandom.alphanumeric(18))
  end
  let!(:sf_contact) do
    create(:salesforce_contact, pi_accounts_unique_id__c: class_teacher.teacher_id, sfid: SecureRandom.alphanumeric(18))
  end

  around do |example|
    ClimateControl.modify(SALESFORCE_ENABLED: 'true') { example.run }
  end

  context 'when the job has run' do
    before { perform_job }

    it 'syncs all FIELD_MAPPINGS to the correct class teacher values' do
      sf_class_teacher = Salesforce::ClassTeacher.find_by(contactclassroomaffiliationuuid__c: class_teacher.id)
      described_class::FIELD_MAPPINGS.each do |sf_field, class_teacher_field|
        expected = Salesforce::ClassTeacher.type_for_attribute(sf_field).cast(class_teacher.send(class_teacher_field))
        expect(sf_class_teacher.send(sf_field)).to eq(expected)
      end
    end
  end

  context 'when the Salesforce class teacher fails to save' do
    let(:sf_class_teacher) { instance_double(Salesforce::ClassTeacher) }

    before do
      allow(Salesforce::ClassTeacher).to receive(:find_or_initialize_by)
        .with(contactclassroomaffiliationuuid__c: class_teacher.id).and_return(sf_class_teacher)
      allow(sf_class_teacher).to receive(:attributes=)
      allow(sf_class_teacher).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
    end

    it 'raises an error' do
      expect { perform_job }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  context 'when the parent Classroom__c is not yet synced to Salesforce' do
    before { sf_school_class.update!(sfid: nil) }

    it 'retries the job to defer the affiliation write' do
      expect { perform_job }.to have_enqueued_job(described_class).with(class_teacher_id: class_teacher.id)
    end

    it 'does not write the affiliation to the mirror' do
      perform_job
      expect(Salesforce::ClassTeacher.find_by(contactclassroomaffiliationuuid__c: class_teacher.id)).to be_nil
    end
  end

  context 'when there is no Salesforce::SchoolClass row for the class teacher' do
    before { sf_school_class.destroy }

    it 'retries the job' do
      expect { perform_job }.to have_enqueued_job(described_class).with(class_teacher_id: class_teacher.id)
    end

    it 'does not write the affiliation to the mirror' do
      perform_job
      expect(Salesforce::ClassTeacher.find_by(contactclassroomaffiliationuuid__c: class_teacher.id)).to be_nil
    end
  end

  context 'when the parent Contact is not yet synced to Salesforce' do
    before { sf_contact.update!(sfid: nil) }

    it 'retries the job to defer the affiliation write' do
      expect { perform_job }.to have_enqueued_job(described_class).with(class_teacher_id: class_teacher.id)
    end

    it 'does not write the affiliation to the mirror' do
      perform_job
      expect(Salesforce::ClassTeacher.find_by(contactclassroomaffiliationuuid__c: class_teacher.id)).to be_nil
    end
  end

  context 'when there is no Salesforce::Contact row for the class teacher' do
    before { sf_contact.destroy }

    it 'retries the job' do
      expect { perform_job }.to have_enqueued_job(described_class).with(class_teacher_id: class_teacher.id)
    end

    it 'does not write the affiliation to the mirror' do
      perform_job
      expect(Salesforce::ClassTeacher.find_by(contactclassroomaffiliationuuid__c: class_teacher.id)).to be_nil
    end
  end

  context 'when SALESFORCE_ENABLED is false' do
    around do |example|
      ClimateControl.modify(SALESFORCE_ENABLED: 'false') { example.run }
    end

    it 'discards the job without syncing' do
      perform_job
      expect(Salesforce::ClassTeacher.find_by(contactclassroomaffiliationuuid__c: class_teacher.id)).to be_nil
    end
  end

  describe '#concurrency_key_id' do
    it 'returns the class_teacher_id' do
      job = described_class.new(class_teacher_id: class_teacher.id)
      expect(job.send(:concurrency_key_id)).to eq(class_teacher.id)
    end
  end
end
