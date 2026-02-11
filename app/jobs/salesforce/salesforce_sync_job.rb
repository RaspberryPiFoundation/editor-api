# # frozen_string_literal: true

module Salesforce
  class SalesforceSyncJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      perform_throttle: [2, 1.second]
    )

    SalesforceRecordNotFound = Class.new(StandardError)
    SkipBecauseSalesforceIsDisabled = Class.new(StandardError)

    include ActionView::Helpers::SanitizeHelper

    queue_as :salesforce_sync

    discard_on SkipBecauseSalesforceIsDisabled

    before_perform do |_job|
      unless ENV.fetch('SALESFORCE_ENABLED', 'true') == 'true'
        raise SkipBecauseSalesforceIsDisabled, 'SALESFORCE_ENABLED is not true.'
      end
    end

    def perform(*)
      raise NotImplementedError, 'Subclasses must implement perform'
    end

    # TODO Consider implementing private utilities here, e.g. truncate_value
  end
end

