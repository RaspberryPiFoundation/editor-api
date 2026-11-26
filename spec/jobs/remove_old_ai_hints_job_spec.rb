# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RemoveOldAiHintsJob do
  it 'removes hints older than a day and keeps newer ones' do
    old_hint = create(:ai_hint, created_at: 2.days.ago)
    new_hint = create(:ai_hint, created_at: 1.hour.ago)

    described_class.perform_now

    expect(AiHint.pluck(:id)).to contain_exactly(new_hint.id)
    expect(AiHint.exists?(old_hint.id)).to be(false)
  end
end
