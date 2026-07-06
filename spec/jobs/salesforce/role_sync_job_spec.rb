# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Salesforce::RoleSyncJob, :requires_salesforce_db do
  subject(:perform_job) { described_class.perform_now(role_id: role.id) }

  let(:role) { create(:role) }
  let!(:sf_school) do
    create(:salesforce_school, editoruuid__c: role.school_id, sfid: SecureRandom.alphanumeric(18))
  end
  let!(:sf_contact) do
    create(:salesforce_contact, pi_accounts_unique_id__c: role.user_id, sfid: SecureRandom.alphanumeric(18))
  end

  around do |example|
    ClimateControl.modify(SALESFORCE_ENABLED: 'true') { example.run }
  end

  it 'syncs all FIELD_MAPPINGS to the correct role values' do
    perform_job
    sf_role = Salesforce::Role.find_by(affiliation_id__c: role.id)
    described_class::FIELD_MAPPINGS.each do |sf_field, role_field|
      expected = Salesforce::Role.type_for_attribute(sf_field).cast(role.send(role_field))
      expect(sf_role.send(sf_field)).to eq(expected),
                                        "Expected #{sf_field} to equal role.#{role_field}"
    end
  end

  it 'sets editor_type__c from the school user_origin' do
    perform_job
    sf_role = Salesforce::Role.find_by(affiliation_id__c: role.id)
    expect(sf_role.editor_type__c).to eq(role.school.user_origin)
  end

  context 'when the Salesforce role fails to save' do
    let(:sf_role) { instance_double(Salesforce::Role) }

    before do
      allow(Salesforce::Role).to receive(:find_or_initialize_by).with(affiliation_id__c: role.id).and_return(sf_role)
      allow(sf_role).to receive(:attributes=)
      allow(sf_role).to receive(:editor_type__c=)
      allow(sf_role).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
    end

    it 'raises an error' do
      expect { perform_job }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  context 'when the role is a student role' do
    let(:role) { create(:student_role) }

    it 'does not create a Salesforce role record' do
      perform_job
      expect(Salesforce::Role.find_by(affiliation_id__c: role.id)).to be_nil
    end
  end

  context 'when the parent Editor__c is not yet synced to Salesforce' do
    before { sf_school.update!(sfid: nil) }

    it 'retries the job to defer the affiliation write' do
      expect { perform_job }.to have_enqueued_job(described_class).with(role_id: role.id)
    end

    it 'does not write the affiliation to the mirror' do
      perform_job
      expect(Salesforce::Role.find_by(affiliation_id__c: role.id)).to be_nil
    end
  end

  context 'when there is no Salesforce::School row for the role school' do
    before { sf_school.destroy }

    it 'retries the job' do
      expect { perform_job }.to have_enqueued_job(described_class).with(role_id: role.id)
    end

    it 'does not write the affiliation to the mirror' do
      perform_job
      expect(Salesforce::Role.find_by(affiliation_id__c: role.id)).to be_nil
    end
  end

  context 'when the parent Contact is not yet synced to Salesforce' do
    before { sf_contact.update!(sfid: nil) }

    it 'retries the job to defer the affiliation write' do
      expect { perform_job }.to have_enqueued_job(described_class).with(role_id: role.id)
    end

    it 'does not write the affiliation to the mirror' do
      perform_job
      expect(Salesforce::Role.find_by(affiliation_id__c: role.id)).to be_nil
    end
  end

  context 'when there is no Salesforce::Contact row for the role user' do
    before { sf_contact.destroy }

    it 'retries the job' do
      expect { perform_job }.to have_enqueued_job(described_class).with(role_id: role.id)
    end

    it 'does not write the affiliation to the mirror' do
      perform_job
      expect(Salesforce::Role.find_by(affiliation_id__c: role.id)).to be_nil
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
      expect(Salesforce::Role.find_by(affiliation_id__c: role.id)).to be_nil
    end
  end

  describe '#concurrency_key_id' do
    it 'returns the role_id' do
      job = described_class.new(role_id: role.id)
      expect(job.send(:concurrency_key_id)).to eq(role.id)
    end
  end
end
