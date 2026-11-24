# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AiHint do
  subject(:ai_hint) { build(:ai_hint) }

  describe 'validations' do
    it 'has a valid factory' do
      expect(ai_hint).to be_valid
    end

    it 'requires a user_id' do
      ai_hint.user_id = nil
      expect(ai_hint).not_to be_valid
    end

    it 'rejects an unknown status' do
      ai_hint.status = 'random'
      expect(ai_hint).not_to be_valid
    end
  end

  it 'defaults to pending' do
    expect(described_class.new).to be_pending
  end

  describe '#complete!' do
    before { ai_hint.save! }

    it 'saves the hint and marks it completed' do
      ai_hint.complete!('Check the variable name')
      expect(ai_hint.reload).to have_attributes(status: 'completed', hint: 'Check the variable name')
    end

    it 'clears the input' do
      ai_hint.complete!('Check the variable name')
      expect(ai_hint.reload.input).to be_nil
    end
  end

  describe '#fail!' do
    before { ai_hint.save! }

    it 'marks it failed without a hint' do
      ai_hint.fail!
      expect(ai_hint.reload).to have_attributes(status: 'failed', hint: nil)
    end

    it 'clears the input' do
      ai_hint.fail!
      expect(ai_hint.reload.input).to be_nil
    end
  end
end
