# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salesforce::SchoolSyncJob, :requires_salesforce_db do
  subject(:perform_job) { described_class.perform_now(school_id: school.id) }

  let(:school) { create(:school) }

  around do |example|
    ClimateControl.modify(SALESFORCE_ENABLED: 'true') { example.run }
  end

  context 'when the job has run' do
    before { perform_job }

    it 'syncs all FIELD_MAPPINGS to the correct school values' do
      sf_school = Salesforce::School.find_by(editoruuid__c: school.id)
      described_class::FIELD_MAPPINGS.each do |sf_field, school_field|
        expected = Salesforce::School.type_for_attribute(sf_field).cast(school.send(school_field))
        expect(sf_school.send(sf_field)).to eq(expected),
                                            "Expected #{sf_field} to equal school.#{school_field}"
      end
    end

    context 'when an address field is very long' do
      let(:school) { create(:school, address_line_1: '❌' * 300) }

      it 'truncates addressline1__c' do
        sf_school = Salesforce::School.find_by(editoruuid__c: school.id)
        expect(sf_school.addressline1__c).to end_with('…')
        expect(sf_school.addressline1__c.length).to be < school.address_line_1.length
      end
    end

    context 'when the school is verified' do
      let(:school) { create(:verified_school) }

      it 'syncs verifiedat__c' do
        sf_school = Salesforce::School.find_by(editoruuid__c: school.id)
        expect(sf_school.verifiedat__c).to eq(school.verified_at)
      end
    end

    context 'when the school is rejected' do
      let(:school) { create(:school, rejected_at: Time.current) }

      it 'syncs rejectedat__c' do
        sf_school = Salesforce::School.find_by(editoruuid__c: school.id)
        expect(sf_school.rejectedat__c).to eq(school.rejected_at)
      end
    end
  end

  context 'when the Salesforce school fails to save' do
    let(:sf_school) { instance_double(Salesforce::School) }

    before do
      allow(Salesforce::School).to receive(:find_or_initialize_by).with(editoruuid__c: school.id).and_return(sf_school)
      allow(sf_school).to receive(:attributes=)
      allow(sf_school).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
    end

    it 'raises an error' do
      expect { perform_job }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  context 'when SALESFORCE_ENABLED is false' do
    around do |example|
      ClimateControl.modify(SALESFORCE_ENABLED: 'false') do
        example.run
      end
    end

    it 'discards the job without syncing' do
      perform_job
      expect(Salesforce::School.find_by(editoruuid__c: school.id)).to be_nil
    end
  end

  describe '#concurrency_key_id' do
    it 'returns the school_id' do
      job = described_class.new(school_id: school.id)
      expect(job.send(:concurrency_key_id)).to eq(school.id)
    end
  end
end
