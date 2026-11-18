# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User settings API' do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:user) { create(:user) }
  let(:defaults) { { 'theme' => nil, 'font_size' => 'small', 'ai_hints_enabled' => true } }

  describe 'GET /api/user_settings' do
    context 'when logged out' do
      it 'returns 401' do
        get '/api/user_settings'
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the user has no saved settings' do
      before { authenticated_in_hydra_as(user) }

      it 'returns the defaults' do
        get('/api/user_settings', headers:)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq('settings' => defaults)
      end

      it 'does not create a row' do
        expect { get('/api/user_settings', headers:) }.not_to change(UserSetting, :count)
      end
    end

    context 'when the user has saved settings' do
      before do
        authenticated_in_hydra_as(user)
        create(:user_setting, user_id: user.id, settings: { 'theme' => 'dark' })
      end

      it 'returns saved values merged over the defaults' do
        get('/api/user_settings', headers:)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq('settings' => defaults.merge('theme' => 'dark'))
      end
    end

    context 'when another user has saved settings' do
      before do
        authenticated_in_hydra_as(user)
        create(:user_setting, settings: { 'theme' => 'dark' })
      end

      it 'does not return them' do
        get('/api/user_settings', headers:)
        expect(response.parsed_body).to eq('settings' => defaults)
      end
    end
  end

  describe 'PATCH /api/user_settings' do
    context 'when logged out' do
      it 'returns 401' do
        patch '/api/user_settings', params: { settings: { theme: 'dark' } }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when logged in' do
      before { authenticated_in_hydra_as(user) }

      it 'creates a row on the first update' do
        expect do
          patch '/api/user_settings', params: { settings: { theme: 'dark' } }, headers:, as: :json
        end.to change(UserSetting, :count).by(1)
      end

      it 'returns the merged settings' do
        patch '/api/user_settings', params: { settings: { theme: 'dark' } }, headers:, as: :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq('settings' => defaults.merge('theme' => 'dark'))
      end

      it 'stores booleans as booleans' do
        patch '/api/user_settings', params: { settings: { ai_hints_enabled: false } }, headers:, as: :json

        expect(UserSetting.find_by(user_id: user.id).settings).to eq('ai_hints_enabled' => false)
      end

      it 'resets a setting to its default when sent null' do
        create(:user_setting, user_id: user.id, settings: { 'theme' => 'dark' })

        patch '/api/user_settings', params: { settings: { theme: nil } }, headers:, as: :json

        expect(response.parsed_body).to eq('settings' => defaults)
      end

      it 'returns 422 when settings is not an object' do
        patch '/api/user_settings', params: { settings: 'dark' }, headers:, as: :json
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns 400 when settings is missing' do
        patch '/api/user_settings', params: {}, headers:, as: :json
        expect(response).to have_http_status(:bad_request)
      end

      it 'does not save anything when invalid' do
        expect do
          patch '/api/user_settings', params: { settings: { colour: 'red' } }, headers:, as: :json
        end.not_to change(UserSetting, :count)
      end

      it 'locks the row while updating so concurrent updates are not lost' do
        allow(UserSetting).to receive(:lock).and_call_original

        patch '/api/user_settings', params: { settings: { theme: 'dark' } }, headers:, as: :json

        expect(UserSetting).to have_received(:lock)
      end

      it 'updates the existing row, only changing the keys sent' do
        create(:user_setting, user_id: user.id, settings: { 'theme' => 'dark' })

        patch '/api/user_settings', params: { settings: { font_size: 'large' } }, headers:, as: :json

        expect(response).to have_http_status(:ok)
        expect(UserSetting.where(user_id: user.id).pluck(:settings)).to eq([{ 'theme' => 'dark', 'font_size' => 'large' }])
      end

      it 'returns 422 with the validation error for an invalid setting' do
        create(:user_setting, user_id: user.id)

        patch '/api/user_settings', params: { settings: { colour: 'red' } }, headers:, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body['error']).to include("'colour' is not a valid setting")
        expect(response.parsed_body['error']).not_to include('User')
      end
    end
  end
end
