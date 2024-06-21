# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Accepting an invitations', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }

  context 'when user is not logged in' do
    it 'responds 401 Unauthorized' do
      put('/api/teacher_invitations/fake-token/accept')
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when user is logged in' do
    before do
      authenticated_in_hydra_as(user)
    end

    context 'when invitation does not exist' do
      let(:invitation) { build(:invitation) }
      let!(:token) { invitation.generate_token_for(:teacher_invitation) }

      it 'responds 404 Not Found' do
        put("/api/teacher_invitations/#{token}/accept", headers:)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when invitation exists' do
      let(:school) { create(:verified_school) }
      let(:invitation_email) { user.email }
      let(:invitation) { create(:invitation, email_address: invitation_email, school:) }
      let!(:token) { invitation.generate_token_for(:teacher_invitation) }

      context 'when invitation token is not valid because invitation email has changed' do
        before do
          invitation.update!(email_address: "not-#{invitation.email_address}")
        end

        it 'responds 403 Forbidden' do
          put("/api/teacher_invitations/#{token}/accept", headers:)
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'when invitation token is not valid because token has expired' do
        it 'responds 403 Forbidden' do
          travel 31.days do
            put("/api/teacher_invitations/#{token}/accept", headers:)
          end
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'when invitation email does not match user email' do
        let(:invitation_email) { "not-#{user.email}" }

        it 'responds 403 Forbidden' do
          put("/api/teacher_invitations/#{token}/accept", headers:)
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'when user already has student role for the same school' do
        before do
          Role.student.create!(user_id: user.id, school:)
        end

        it 'responds 422 Unprocessable entity' do
          put("/api/teacher_invitations/#{token}/accept", headers:)

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'does not give the user the teacher role for the school to which they have been invited' do
          put("/api/teacher_invitations/#{token}/accept", headers:)

          expect(user).not_to be_school_teacher(school)
        end

        it 'includes validation errors in response' do
          put("/api/teacher_invitations/#{token}/accept", headers:)

          json = JSON.parse(response.body)
          expect(json['error']).to eq({ 'base' => ['Cannot create teacher role as this user already has the student role for this school'] })
        end

        it 'does not set the accepted_at timestamp on the invitation' do
          freeze_time(with_usec: false) do
            put("/api/teacher_invitations/#{token}/accept", headers:)

            expect(invitation.reload.accepted_at).to be_blank
          end
        end
      end

      context 'when user already has teacher role for the same school' do
        before do
          Role.teacher.create!(user_id: user.id, school:)
        end

        it 'responds 422 Unprocessable entity' do
          put("/api/teacher_invitations/#{token}/accept", headers:)

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'leaves the user with the teacher role for that school' do
          put("/api/teacher_invitations/#{token}/accept", headers:)

          expect(user).to be_school_teacher(school)
        end

        it 'includes validation errors in response' do
          put("/api/teacher_invitations/#{token}/accept", headers:)

          json = JSON.parse(response.body)
          expect(json['error']).to eq({ 'role' => ['has already been taken'] })
        end

        it 'does not set the accepted_at timestamp on the invitation' do
          freeze_time(with_usec: false) do
            put("/api/teacher_invitations/#{token}/accept", headers:)

            expect(invitation.reload.accepted_at).to be_blank
          end
        end
      end

      context 'when user already has a role for another school' do
        let(:another_shool) { create(:school) }

        before do
          Role.teacher.create!(user_id: user.id, school: another_shool)
        end

        it 'responds 422 Unprocessable entity' do
          put("/api/teacher_invitations/#{token}/accept", headers:)

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'does not give the user the teacher role for the school to which they have been invited' do
          put("/api/teacher_invitations/#{token}/accept", headers:)

          expect(user).not_to be_school_teacher(school)
        end

        it 'includes validation errors in response' do
          put("/api/teacher_invitations/#{token}/accept", headers:)

          json = JSON.parse(response.body)
          expect(json['error']).to eq({ 'base' => ['Cannot create role as this user already has a role in a different school'] })
        end

        it 'does not set the accepted_at timestamp on the invitation' do
          freeze_time(with_usec: false) do
            put("/api/teacher_invitations/#{token}/accept", headers:)

            expect(invitation.reload.accepted_at).to be_blank
          end
        end
      end

      context 'when invitation token is valid' do
        it 'responds 200 OK' do
          put("/api/teacher_invitations/#{token}/accept", headers:)

          expect(response).to have_http_status(:ok)
        end

        it 'gives the user the teacher role for the school to which they have been invited' do
          put("/api/teacher_invitations/#{token}/accept", headers:)

          expect(user).to be_school_teacher(school)
        end

        it 'sets the accepted_at timestamp on the invitation' do
          freeze_time(with_usec: false) do
            put("/api/teacher_invitations/#{token}/accept", headers:)

            expect(invitation.reload.accepted_at).to eq(Time.current)
          end
        end
      end

      context 'when invitation has already been accepted' do
        let(:original_accepted_at) { 1.week.ago.noon }

        before do
          invitation.update!(accepted_at: original_accepted_at)
        end

        it 'responds 200 OK' do
          put("/api/teacher_invitations/#{token}/accept", headers:)

          expect(response).to have_http_status(:ok)
        end

        it 'does not update the accepted_at timestamp on the invitation' do
          put("/api/teacher_invitations/#{token}/accept", headers:)

          expect(invitation.reload.accepted_at).to eq(original_accepted_at)
        end
      end

      context 'when user already has owner role for the same school' do
        before do
          Role.owner.create!(user_id: user.id, school:)
        end

        it 'responds 200 OK' do
          put("/api/teacher_invitations/#{token}/accept", headers:)

          expect(response).to have_http_status(:ok)
        end

        it 'gives the user the teacher role for the school to which they have been invited' do
          put("/api/teacher_invitations/#{token}/accept", headers:)

          expect(user).to be_school_teacher(school)
        end

        it 'leaves the user with the owner role for that school' do
          put("/api/teacher_invitations/#{token}/accept", headers:)

          expect(user).to be_school_owner(school)
        end

        it 'sets the accepted_at timestamp on the invitation' do
          freeze_time(with_usec: false) do
            put("/api/teacher_invitations/#{token}/accept", headers:)

            expect(invitation.reload.accepted_at).to eq(Time.current)
          end
        end
      end
    end
  end
end
