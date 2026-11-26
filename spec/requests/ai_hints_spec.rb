# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AiHints' do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:student) { create(:student, school:) }
  let(:params) { { message: 'message', trace: 'trace', runtime: 'runtime', code: 'code' } }

  before do
    Flipper.enable(:ai_friendly_errors)
  end

  describe 'POST /api/ai_hints' do
    it 'does not allow logged-out users' do
      post('/api/ai_hints', params:)

      expect(response).to have_http_status(:unauthorized)
    end

    it 'is protected by a feature flag' do
      Flipper.disable(:ai_friendly_errors)
      authenticated_in_hydra_as(student)

      post('/api/ai_hints', headers:, params:)

      expect(response).to have_http_status(:unauthorized)
    end

    it 'disallows requests over 100KB in size' do
      authenticated_in_hydra_as(student)

      post('/api/ai_hints', headers:, params: params.merge(code: 'a' * 100.kilobytes))

      expect(response).to have_http_status(:content_too_large)
    end

    it 'requires message, trace, runtime and code params' do
      authenticated_in_hydra_as(student)

      post('/api/ai_hints', headers:, params: params.except(:code))

      expect(response).to have_http_status(:bad_request)
    end

    context 'with a well-formed request' do
      before { authenticated_in_hydra_as(student) }

      it 'returns 202 with the id' do
        post('/api/ai_hints', headers:, params:)

        expect(response).to have_http_status(:accepted)
        expect(response.parsed_body[:id]).to eq(AiHint.last.id)
      end

      it 'creates a pending hint for the current user with the input' do
        post('/api/ai_hints', headers:, params:)

        expect(AiHint.last).to have_attributes(
          user_id: student.id,
          status: 'pending',
          input: params.stringify_keys
        )
      end

      it 'enqueues the job' do
        expect { post('/api/ai_hints', headers:, params:) }
          .to have_enqueued_job(GenerateAiHintJob).with(ai_hint_id: kind_of(String))
      end
    end
  end

  describe 'GET /api/ai_hints/:id' do
    let(:ai_hint) { create(:ai_hint, user_id: student.id) }

    it 'does not allow logged-out users' do
      get "/api/ai_hints/#{ai_hint.id}"

      expect(response).to have_http_status(:unauthorized)
    end

    it 'is protected by a feature flag' do
      Flipper.disable(:ai_friendly_errors)
      authenticated_in_hydra_as(student)

      get("/api/ai_hints/#{ai_hint.id}", headers:)

      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated' do
      before { authenticated_in_hydra_as(student) }

      it 'returns pending' do
        get("/api/ai_hints/#{ai_hint.id}", headers:)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq('status' => 'pending')
      end

      it 'returns the hint when completed' do
        ai_hint.complete!('Check the variable name')

        get("/api/ai_hints/#{ai_hint.id}", headers:)

        expect(response.parsed_body).to eq('status' => 'completed', 'hint' => 'Check the variable name')
      end

      it 'returns failed' do
        ai_hint.fail!

        get("/api/ai_hints/#{ai_hint.id}", headers:)

        expect(response.parsed_body).to eq('status' => 'failed')
      end

      it "returns 404 for another user's hint" do
        other_hint = create(:ai_hint)

        get("/api/ai_hints/#{other_hint.id}", headers:)

        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for an unknown id' do
        get("/api/ai_hints/#{SecureRandom.uuid}", headers:)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
