# frozen_string_literal: true

module Api
  class TeacherInvitationsController < ApiController
    rescue_from ActiveSupport::MessageVerifier::InvalidSignature, with: -> { denied }

    before_action :authorize_user
    before_action :load_invitation
    before_action :ensure_invitation_email_matches_user_email

    def show
      render :show, formats: [:json], status: :ok
    end

    private

    def load_invitation
      @invitation = Invitation.find_by_token_for!(:teacher_invitation, params[:token])
    end

    def ensure_invitation_email_matches_user_email
      return if @invitation.email_address == current_user.email

      render json: { error: 'Invitation email does not match user email' }, status: :forbidden
    end
  end
end
