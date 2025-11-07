# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Feedback::SetRead, type: :unit do
  let(:feedback) { create(:feedback) }

  describe '.call' do
    context 'when set_read is successful' do
      it 'returns a successful operation response' do
        response = described_class.call(feedback: feedback)
        expect(response.success?).to be(true)
      end

      it 'returns the updated feedback' do
        response = described_class.call(feedback: feedback)
        expect(response[:feedback]).to eq(feedback)
      end

      it 'returns read_at' do
        response = described_class.call(feedback: feedback)
        expect(response[:feedback].read_at).to be_present
      end

      it 'returns read_at as a timestamp' do
        response = described_class.call(feedback: feedback)
        expect(response[:feedback].read_at).to be_a(ActiveSupport::TimeWithZone)
      end
    end
  end
end
