# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Feedback::Delete, type: :unit do
  let(:feedback) { create(:feedback) }
  let(:feedback_id) { feedback.id }

  describe '.call' do
    context 'when deletion is successful' do
      it 'returns a successful operation response' do
        response = described_class.call(feedback_id:)
        expect(response.success?).to be(true)
      end

      it 'deletes the feedback' do
        feedback_id = feedback.id
        expect { described_class.call(feedback_id:) }.to change(Feedback, :count).by(-1)
        expect(Feedback.where(id: feedback_id)).to be_empty
      end
    end

    context 'when deletion fails' do
      let(:feedback_id) { 'does-not-exist' }

      before do
        allow(Sentry).to receive(:capture_exception)
      end

      it 'returns a failed operation response' do
        response = described_class.call(feedback_id:)
        expect(response.success?).to be(false)
      end

      it 'returns the error message in the operation response' do
        response = described_class.call(feedback_id:)
        expect(response[:error]).to match(/does-not-exist/)
      end

      it 'sent the exception to Sentry' do
        described_class.call(feedback_id:)
        expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
      end
    end
  end
end
