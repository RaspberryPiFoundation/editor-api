# frozen_string_literal: true

module Salesforce
  class SalesforceSyncJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency

    # Serialise concurrent performs for the same record (same class + record ID)
    # to prevent TOCTOU races on find_or_initialize_by + save!, while allowing
    # jobs for different records to run fully in parallel.
    good_job_control_concurrency_with(
      perform_limit: 1,
      key: -> { "#{self.class.name}/#{concurrency_key_id}" }
    )

    class SalesforceRecordNotFound < StandardError
    end

    class SkipBecauseSalesforceIsDisabled < StandardError
    end

    discard_on SkipBecauseSalesforceIsDisabled

    retry_on SalesforceRecordNotFound, wait: :polynomially_longer, attempts: 10

    queue_as :salesforce_sync

    before_perform do |_job|
      salesforce_enabled = FeatureFlags.salesforce_sync?
      raise SkipBecauseSalesforceIsDisabled, 'SALESFORCE_ENABLED is not true.' unless salesforce_enabled
    end

    def perform(*)
      raise NotImplementedError, 'Subclasses must implement perform'
    end

    private

    def concurrency_key_id
      raise NotImplementedError, "#{self.class.name} must implement concurrency_key_id"
    end

    # Guard a write that resolves a Salesforce parent via an external-ID lookup
    # (`__r__<external_id_field>`). Heroku Connect rejects the INSERT permanently with
    # "Foreign key external ID ... not found" if the parent isn't yet in Salesforce, and
    # the mirror row stays FAILED forever (no auto-retry). Raising SalesforceRecordNotFound
    # here defers the write via the retry_on declared on this base class, so the job
    # self-heals once the parent lands.
    def ensure_parent_synced!(model, external_id_field, external_id, label)
      return if model.where(external_id_field => external_id).where.not(sfid: nil).exists?

      raise SalesforceRecordNotFound,
            "#{label} not yet synced for #{external_id_field}: #{external_id}"
    end

    def truncate_value(sf_field:, value:)
      column = self.class::MODEL_CLASS.column_for_attribute(sf_field)
      return value if column.limit.nil?

      value.truncate(column.limit, omission: '…')
    end
  end
end
