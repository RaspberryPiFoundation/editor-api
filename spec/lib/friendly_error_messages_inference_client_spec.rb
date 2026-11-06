# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FriendlyErrorMessagesInferenceClient do
  subject(:client) { described_class.new }

  let(:mock_client) { instance_double(OpenAI::Client) }
  let(:chat) { instance_double(OpenAI::Resources::Chat) }
  let(:completions) { instance_double(OpenAI::Resources::Chat::Completions) }

  def stub_completion(content)
    message = instance_double(OpenAI::Models::Chat::ChatCompletionMessage, content:)
    choice = instance_double(OpenAI::Models::Chat::ChatCompletion::Choice, message:)
    completion = instance_double(OpenAI::Models::Chat::ChatCompletion, choices: [choice])
    allow(completions).to receive(:create).and_return(completion)
  end

  context 'when BYPASS_FEM_INFERENCE is false' do
    around do |example|
      ClimateControl.modify(BYPASS_FEM_INFERENCE: 'false') do
        example.run
      end
    end

    before do
      allow(OpenAI::Client).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:chat).and_return(chat)
      allow(chat).to receive(:completions).and_return(completions)
    end

    it 'calls the inference server' do
      stub_completion('A friendly error message')

      result = client.get_message('', '', '', '')
      expect(result).to eq 'A friendly error message'
    end

    it 'throws an error when the inference call times out' do
      allow(completions).to receive(:create).and_raise(OpenAI::Errors::APITimeoutError.new(url: 'http://some_url'))

      expect { client.get_message('', '', '', '') }.to raise_exception(FriendlyErrorMessagesInferenceClient::Error)
    end

    it 'throws an error when the inference server is down' do
      allow(completions).to receive(:create).and_raise(OpenAI::Errors::APIConnectionError.new(url: 'http://some_url'))

      expect { client.get_message('', '', '', '') }.to raise_exception(FriendlyErrorMessagesInferenceClient::Error)
    end

    it 'throws an error when the inference server returns nothing' do
      stub_completion(nil)

      expect { client.get_message('', '', '', '') }.to raise_exception(FriendlyErrorMessagesInferenceClient::Error)
    end

    it 'throws an error when the inference server returns a response that is too long' do
      stub_completion('a' * 1000)

      expect { client.get_message('', '', '', '') }.to raise_exception(FriendlyErrorMessagesInferenceClient::Error)
    end
  end

  context 'when BYPASS_FEM_INFERENCE is true' do
    around do |example|
      ClimateControl.modify(BYPASS_FEM_INFERENCE: 'true') do
        example.run
      end
    end

    it 'returns a mock response' do
      result = client.get_message('', '', '', '')
      expect(result).to eq 'This is a placeholder friendly error message.'
    end
  end
end
