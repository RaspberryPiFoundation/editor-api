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

    def accept
      role = Role.teacher.build(user_id: current_user.id, school: @invitation.school)
      if role.valid?
        role.save
        @invitation.update!(accepted_at: Time.current) if @invitation.accepted_at.blank?
        head :ok
      else
        render json: { error: role.errors }, status: :unprocessable_entity
      end
    end

    private

    def load_invitation
      @invitation = TeacherInvitation.find_by_token_for!(:teacher_invitation, params[:token])
    end

    def ensure_invitation_email_matches_user_email
      return if @invitation.email_address == current_user.email

      render json: { error: 'Invitation email does not match user email' }, status: :forbidden
    end
  end
end
