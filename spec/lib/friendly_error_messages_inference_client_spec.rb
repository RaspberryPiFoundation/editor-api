# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FriendlyErrorMessagesInferenceClient do
  subject(:client) { described_class.new }

  let(:mock_client) { instance_double(OpenAI::Client) }

  context 'when BYPASS_FEM_INFERENCE is false' do
    around do |example|
      ClimateControl.modify(BYPASS_FEM_INFERENCE: 'false') do
        example.run
      end
    end

    it 'calls the inference server' do
      responses = instance_double(OpenAI::Resources::Responses)
      response = instance_double(OpenAI::Models::Responses::Response, output_text: 'A friendly error message')
      allow(OpenAI::Client).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:responses).and_return(responses)
      allow(responses).to receive(:create).and_return(response)

      result = client.get_message('', '', '', '')
      expect(result).to eq 'A friendly error message'
    end

    it 'throws an error when the inference call times out' do
      responses = instance_double(OpenAI::Resources::Responses)
      allow(OpenAI::Client).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:responses).and_return(responses)
      allow(responses).to receive(:create).and_raise(OpenAI::Errors::APITimeoutError.new(url: 'http://some_url'))

      expect { client.get_message('', '', '', '') }.to raise_exception(FriendlyErrorMessagesInferenceClient::Error)
    end

    it 'throws an error when the inference server is down' do
      responses = instance_double(OpenAI::Resources::Responses)
      allow(OpenAI::Client).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:responses).and_return(responses)
      allow(responses).to receive(:create).and_raise(OpenAI::Errors::APIConnectionError.new(url: 'http://some_url'))

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
