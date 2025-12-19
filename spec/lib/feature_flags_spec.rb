# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeatureFlags do
  describe '.immediate_school_onboarding?' do
    it 'returns true when ENV is set to "true"' do
      ClimateControl.modify(ENABLE_IMMEDIATE_SCHOOL_ONBOARDING: 'true') do
        expect(described_class.immediate_school_onboarding?).to be(true)
      end
    end

    it 'returns false when ENV is not set' do
      ClimateControl.modify(ENABLE_IMMEDIATE_SCHOOL_ONBOARDING: nil) do
        expect(described_class.immediate_school_onboarding?).to be(false)
      end
    end

    it 'returns false when ENV is set to empty string' do
      ClimateControl.modify(ENABLE_IMMEDIATE_SCHOOL_ONBOARDING: '') do
        expect(described_class.immediate_school_onboarding?).to be(false)
      end
    end

    it 'returns false when ENV is set to "false"' do
      ClimateControl.modify(ENABLE_IMMEDIATE_SCHOOL_ONBOARDING: 'false') do
        expect(described_class.immediate_school_onboarding?).to be(false)
      end
    end

    it 'returns false when ENV is set to any other value' do
      ClimateControl.modify(ENABLE_IMMEDIATE_SCHOOL_ONBOARDING: '1') do
        expect(described_class.immediate_school_onboarding?).to be(false)
      end
    end
  end
end
