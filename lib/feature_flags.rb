# frozen_string_literal: true

module FeatureFlags
  def self.salesforce_sync?
    return false if Current.salesforce_sync_suppressed

    ENV['SALESFORCE_ENABLED'] == 'true'
  end

  def self.without_salesforce_sync(&)
    Current.set(salesforce_sync_suppressed: true, &)
  end
end
