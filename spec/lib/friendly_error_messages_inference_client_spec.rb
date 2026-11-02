# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FriendlyErrorMessagesInferenceClient do
  subject(:client) { described_class.new }

  let(:openai_client) { instance_double(OpenAI::Client) }

  context 'when BYPASS_FEM_INFERENCE is false' do
    around do |example|
      ClimateControl.modify(BYPASS_FEM_INFERENCE: 'false') do
        example.run
      end
    end

    it 'calls the inference server' do
      responses = instance_double(OpenAI::Resources::Responses)
      response = instance_double(OpenAI::Models::Responses::Response, output_text: 'A friendly error message')
      allow(OpenAI::Client).to receive(:new).and_return(openai_client)
      allow(openai_client).to receive(:responses).and_return(responses)
      allow(responses).to receive(:create).and_return(response)

      result = client.get_message('', '', '', '')
      expect(result).to eq 'A friendly error message'
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
