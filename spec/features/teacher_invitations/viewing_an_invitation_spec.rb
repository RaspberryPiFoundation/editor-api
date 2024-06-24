# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Viewing an invitations', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }

  context 'when user is not logged in' do
    it 'responds 401 Unauthorized' do
      get('/api/teacher_invitations/fake-token')
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when user is logged in' do
    before do
      authenticated_in_hydra_as(user)
    end

    context 'when invitation does not exist' do
      let(:invitation) { build(:teacher_invitation) }
      let!(:token) { invitation.generate_token_for(:teacher_invitation) }

      it 'responds 404 Not Found' do
        get("/api/teacher_invitations/#{token}", headers:)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when invitation exists' do
      let(:invitation_email) { user.email }
      let(:invitation) { create(:teacher_invitation, email_address: invitation_email) }
      let!(:token) { invitation.generate_token_for(:teacher_invitation) }

      context 'when invitation token is not valid because invitation email has changed' do
        before do
          invitation.update!(email_address: "not-#{invitation.email_address}")
        end

        it 'responds 403 Forbidden' do
          get("/api/teacher_invitations/#{token}", headers:)
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'when invitation token is not valid because token has expired' do
        it 'responds 403 Forbidden' do
          travel 31.days do
            get("/api/teacher_invitations/#{token}", headers:)
          end
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'when invitation email does not match user email' do
        let(:invitation_email) { "not-#{user.email}" }

        it 'responds 403 Forbidden' do
          get("/api/teacher_invitations/#{token}", headers:)
          expect(response).to have_http_status(:forbidden)
        end

        it 'includes error message in response' do
          get("/api/teacher_invitations/#{token}", headers:)

          json = JSON.parse(response.body)
          expect(json['error']).to eq('Invitation email does not match user email')
        end
      end

      context 'when invitation token is valid' do
        it 'responds 200 OK' do
          get("/api/teacher_invitations/#{token}", headers:)
          expect(response).to have_http_status(:ok)
        end

        it 'includes school name in response' do
          get("/api/teacher_invitations/#{token}", headers:)

          json = JSON.parse(response.body)
          expect(json['school_name']).to eq(invitation.school_name)
        end
      end
    end
  end
end
