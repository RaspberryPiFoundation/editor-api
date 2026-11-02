# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'FriendlyErrorMessages' do
  describe 'POST /friendly_error_messages' do
    let(:headers) { { Authorization: UserProfileMock::TOKEN } }
    let(:school) { create(:school) }
    let(:student) { create(:student, school:) }
    let(:mock_client) { instance_double(FriendlyErrorMessagesInferenceClient) }

    before do
      Flipper.enable(:ai_friendly_errors)
    end

    around do |example|
      ClimateControl.modify(BYPASS_FEM_INFERENCE: 'true') do
        example.run
      end
    end

    it 'does not allow logged-out users' do
      post '/api/friendly_error_messages'

      expect(response).to have_http_status(:unauthorized)
    end

    it 'disallows requests over 100KB in size' do
      authenticated_in_hydra_as(student)

      post('/api/friendly_error_messages', headers:, params: { content: 'a' * 100.kilobytes })

      expect(response).to have_http_status(:content_too_large)
    end

    it 'requires message, trace, runtime and code params' do
      authenticated_in_hydra_as(student)

      post('/api/friendly_error_messages', headers:, params: {
             message: 'message',
             trace: 'trace',
             runtime: 'runtime'
           })

      expect(response).to have_http_status(:bad_request)
    end

    it 'is protected by a feature flag' do
      Flipper.disable(:ai_friendly_errors)

      authenticated_in_hydra_as(student)

      post('/api/friendly_error_messages', headers:)

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns a result for a well-formed request' do
      authenticated_in_hydra_as(student)

      post('/api/friendly_error_messages', headers:, params: {
             message: 'message',
             trace: 'trace',
             runtime: 'runtime',
             code: 'code'
           })

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body[:fem]).not_to be_nil
    end

    it 'returns a 503 when the client raises an error' do
      authenticated_in_hydra_as(student)

      allow(FriendlyErrorMessagesInferenceClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:get_message).and_raise(FriendlyErrorMessagesInferenceClient::Error)

      post('/api/friendly_error_messages', headers:, params: {
             message: 'message',
             trace: 'trace',
             runtime: 'runtime',
             code: 'code'
           })

      expect(response).to have_http_status(:bad_gateway)
    end
  end
end
