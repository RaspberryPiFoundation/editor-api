# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GenerateAiHintJob do
  let(:ai_hint) { create(:ai_hint) }
  let(:client) { instance_double(FriendlyErrorMessagesInferenceClient) }

  before do
    allow(FriendlyErrorMessagesInferenceClient).to receive(:new).and_return(client)
    allow(client).to receive(:get_message).and_return('Check the variable name')
    allow(Sentry).to receive(:capture_exception)
  end

  it 'uses the ai_hints queue' do
    expect(described_class.new.queue_name).to eq('ai_hints')
  end

  it 'passes the input to the inference client' do
    described_class.perform_now(ai_hint_id: ai_hint.id)
    expect(client).to have_received(:get_message).with('NameError', 'line 1', 'python', 'print(x)')
  end

  it 'saves the hint and marks it completed' do
    described_class.perform_now(ai_hint_id: ai_hint.id)
    expect(ai_hint.reload).to have_attributes(status: 'completed', hint: 'Check the variable name', input: nil)
  end

  context 'when the hint waited too long in the queue' do
    let(:ai_hint) { create(:ai_hint, created_at: (described_class::MAX_QUEUE_WAIT + 1.second).ago) }

    it 'marks it failed' do
      described_class.perform_now(ai_hint_id: ai_hint.id)
      expect(ai_hint.reload).to have_attributes(status: 'failed', input: nil)
    end

    it 'does not call the inference client' do
      described_class.perform_now(ai_hint_id: ai_hint.id)
      expect(client).not_to have_received(:get_message)
    end
  end

  context 'when the hint is no longer pending' do
    let(:ai_hint) { create(:ai_hint, status: :completed, hint: 'Existing hint') }

    it 'does not call the inference client' do
      described_class.perform_now(ai_hint_id: ai_hint.id)
      expect(client).not_to have_received(:get_message)
    end
  end

  context 'when the inference client fails' do
    let(:error) { FriendlyErrorMessagesInferenceClient::Error.new('boom') }

    before { allow(client).to receive(:get_message).and_raise(error) }

    it 'marks it failed' do
      described_class.perform_now(ai_hint_id: ai_hint.id)
      expect(ai_hint.reload).to have_attributes(status: 'failed', hint: nil, input: nil)
    end

    it 'reports the error to Sentry' do
      described_class.perform_now(ai_hint_id: ai_hint.id)
      expect(Sentry).to have_received(:capture_exception).with(error)
    end
  end

  context 'when an unexpected error is raised' do
    before { allow(client).to receive(:get_message).and_raise(StandardError, 'boom') }

    it 'marks it failed and re-raises the error' do
      expect { described_class.perform_now(ai_hint_id: ai_hint.id) }.to raise_error(StandardError, 'boom')
      expect(ai_hint.reload).to have_attributes(status: 'failed', hint: nil, input: nil)
    end
  end
end
