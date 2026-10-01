# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authentication' do
  let(:user) { create(:user) }

  describe 'POST /auth/rpi' do
    before { stub_auth_for(user) }

    it 'returns to the page the login started from' do
      post '/auth/rpi', params: { returnTo: '/en/projects' }
      follow_redirect!
      expect(response).to redirect_to('/en/projects')
    end

    it 'ignores a return path pointing at another site' do
      post '/auth/rpi', params: { returnTo: '//evil.example.com/en' }
      follow_redirect!
      expect(response).to redirect_to(root_path)
    end

    it 'records when the access token expires' do
      OmniAuth.config.mock_auth[:rpi].credentials = { token: 'an-access-token', expires_at: 1_800_000_000 }
      post '/auth/rpi'
      follow_redirect!
      expect(session[:oauth_expires_at]).to eq(1_800_000_000)
    end

    context 'when the user is an admin' do
      let(:user) { create(:admin_user) }

      it 'lands on the admin dashboard' do
        post '/auth/rpi'
        follow_redirect!
        expect(response).to redirect_to(admin_root_path)
      end

      it 'still returns to the page the login started from' do
        post '/auth/rpi', params: { returnTo: '/en' }
        follow_redirect!
        expect(response).to redirect_to('/en')
      end
    end
  end

  describe 'GET /logout' do
    around do |example|
      ClimateControl.modify(
        EDITOR_APP_HOSTS: 'editor.example.com',
        IDENTITY_URL: 'https://identity.example.com',
        HOST_URL: 'https://editor-api.example.com'
      ) { example.run }
    end

    it 'returns to this application' do
      get 'https://editor-api.example.com/logout'
      expect(response).to redirect_to('https://identity.example.com/logout?returnTo=https://editor-api.example.com')
    end

    it 'returns to the Code Editor when logging out from there' do
      get 'https://editor.example.com/logout'
      expect(response).to redirect_to('https://identity.example.com/logout?returnTo=https://editor.example.com')
    end
  end
end
