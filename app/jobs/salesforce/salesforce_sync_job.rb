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

    def truncate_value(sf_field:, value:)
      column = self.class::MODEL_CLASS.column_for_attribute(sf_field)
      return value if column.limit.nil?

      value.truncate(column.limit, omission: '…')
    end
  end
end
