# frozen_string_literal: true

module FeatureFlags
  def self.immediate_school_onboarding?
    ENV['ENABLE_IMMEDIATE_SCHOOL_ONBOARDING'] == 'true'
  end

  def self.salesforce_sync?
    ENV['SALESFORCE_ENABLED'] == 'true'
  end
end
