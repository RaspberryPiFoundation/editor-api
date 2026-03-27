# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeatureFlags do
  describe '.salesforce_sync?' do
    it 'returns false when ENV is not set' do
      ClimateControl.modify(SALESFORCE_ENABLED: nil) do
        expect(described_class.salesforce_sync?).to be(false)
      end
    end

    it 'returns true when ENV is set to "true"' do
      ClimateControl.modify(SALESFORCE_ENABLED: 'true') do
        expect(described_class.salesforce_sync?).to be(true)
      end
    end

    it 'returns false when ENV is set to "false"' do
      ClimateControl.modify(SALESFORCE_ENABLED: 'false') do
        expect(described_class.salesforce_sync?).to be(false)
      end
    end
  end
end
