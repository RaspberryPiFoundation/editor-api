# frozen_string_literal: true

module FeatureFlags
  def self.salesforce_sync?
    ENV['SALESFORCE_ENABLED'] == 'true'
  end
end
