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
        expect(response[:feedback]).to be_a(Feedback)
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

    context 'when set_read fails' do
      before do
        allow(feedback).to receive(:save!).and_raise(StandardError, 'Some API error')
      end

      it 'returns a failed operation response' do
        response = described_class.call(feedback: feedback)
        expect(response.success?).to be(false)
      end

      it 'does not persist read_at' do
        described_class.call(feedback: feedback)
        feedback.reload
        expect(feedback.read_at).to be_nil
      end

      it 'includes the correct error response' do
        response = described_class.call(feedback: feedback)
        expect(response[:error]).to eq('Some API error')
      end
    end
  end
end
