# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserSetting do
  let(:defaults) { { 'theme' => nil, 'font_size' => 'small', 'ai_hints_enabled' => true } }

  describe 'validations' do
    subject(:user_setting) { build(:user_setting) }

    it 'has a valid default factory' do
      expect(user_setting).to be_valid
    end

    it 'requires a user_id' do
      user_setting.user_id = nil
      expect(user_setting).not_to be_valid
    end

    it 'requires user_id to be unique' do
      user_setting.save!
      expect(build(:user_setting, user_id: user_setting.user_id)).not_to be_valid
    end

    it 'accepts valid settings' do
      user_setting.settings = { 'theme' => 'dark', 'font_size' => 'large', 'ai_hints_enabled' => false }
      expect(user_setting).to be_valid
    end

    it 'rejects unknown keys' do
      user_setting.settings = { 'colour' => 'red' }
      expect(user_setting).not_to be_valid
    end

    it 'rejects values that are not allowed' do
      user_setting.settings = { 'font_size' => 'huge' }
      expect(user_setting).not_to be_valid
    end

    it 'rejects values of the wrong type' do
      user_setting.settings = { 'ai_hints_enabled' => 'no' }
      expect(user_setting).not_to be_valid
    end
  end

  describe '.defaults' do
    it 'returns the default for every registered setting' do
      expect(described_class.defaults).to eq(defaults)
    end
  end

  describe '.for_user' do
    it 'returns defaults when the user has no row' do
      expect(described_class.for_user(SecureRandom.uuid)).to eq(defaults)
    end

    it 'returns stored values merged over defaults' do
      user_setting = create(:user_setting, settings: { 'theme' => 'dark' })
      expect(described_class.for_user(user_setting.user_id)).to eq(defaults.merge('theme' => 'dark'))
    end
  end

  describe '#merged_settings' do
    it 'ignores stored keys that are no longer registered' do
      user_setting = build(:user_setting)
      user_setting.settings = { 'removed_setting' => true, 'font_size' => 'medium' }
      expect(user_setting.merged_settings).to eq(defaults.merge('font_size' => 'medium'))
    end
  end

  describe '#merge_settings' do
    subject(:user_setting) { build(:user_setting, settings: { 'theme' => 'dark' }) }

    it 'keeps existing values and adds new ones' do
      user_setting.merge_settings(font_size: 'large')
      expect(user_setting.settings).to eq('theme' => 'dark', 'font_size' => 'large')
    end

    it 'resets a setting to its default when given nil' do
      user_setting.merge_settings(theme: nil)
      expect(user_setting.settings).to eq({})
    end

    it 'drops stored keys that are no longer registered' do
      user_setting.settings = { 'removed_setting' => true }
      user_setting.merge_settings(font_size: 'small')
      expect(user_setting.settings).to eq('font_size' => 'small')
    end

    it 'makes the record invalid when given an unknown key set to nil' do
      user_setting.merge_settings(colour: nil)
      expect(user_setting).not_to be_valid
    end

    it 'makes the record invalid when given an unknown key' do
      user_setting.merge_settings(colour: 'red')
      expect(user_setting).not_to be_valid
    end
  end
end
