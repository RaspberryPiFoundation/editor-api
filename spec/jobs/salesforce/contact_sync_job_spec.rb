# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salesforce::ContactSyncJob do
  subject(:perform_job) { described_class.perform_now(school_id: school.id) }

  let(:school) { create(:school, creator_agree_to_ux_contact: true) }
  let!(:sf_contact) { create(:salesforce_contact, pi_accounts_unique_id__c: school.creator_id) }

  it 'sets experiencecsagreetouxcontact__c from school.creator_agree_to_ux_contact' do
    perform_job
    expect(sf_contact.reload.experiencecsagreetouxcontact__c).to be(true)
  end

  it 'saves the contact' do
    expect { perform_job }.not_to raise_error
  end

  context 'when the Contact is not found in Salesforce' do
    before { sf_contact.destroy }

    it 'retries the job' do
      expect { perform_job }.to have_enqueued_job(described_class).with(school_id: school.id)
    end
  end

  context 'when the Salesforce contact fails to save' do
    let(:sf_contact_double) { instance_double(Salesforce::Contact) }

    before do
      allow(Salesforce::Contact).to receive(:find_by)
        .with(pi_accounts_unique_id__c: school.creator_id)
        .and_return(sf_contact_double)
      allow(sf_contact_double).to receive(:experiencecsagreetouxcontact__c=)
      allow(sf_contact_double).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
    end

    it 'raises an error' do
      expect { perform_job }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'when SALESFORCE_ENABLED is false' do
    around do |example|
      ClimateControl.modify(SALESFORCE_ENABLED: 'false') do
        example.run
      end
    end

    it 'discards the job without syncing' do
      sf_contact.update!(experiencecsagreetouxcontact__c: false)
      perform_job
      expect(sf_contact.reload.experiencecsagreetouxcontact__c).to be(false)
    end
  end
end
