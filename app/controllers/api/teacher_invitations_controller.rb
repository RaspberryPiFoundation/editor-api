# frozen_string_literal: true

module Api
  class TeacherInvitationsController < ApiController
    rescue_from ActiveSupport::MessageVerifier::InvalidSignature, with: :denied

    before_action :authorize_user
    before_action :load_invitation
    before_action :ensure_invitation_email_matches_user_email
    before_action :authorize_invitation

    def show
      render :show, formats: [:json], status: :ok
    end

    def accept
      role = Role.unscoped.teacher.find_or_initialize_by(user_id: current_user.id, school: @invitation.school)
      role.archived_at = nil
      if role.save
        @invitation.update!(accepted_at: Time.current) if @invitation.accepted_at.blank?
        head :ok
      else
        render json: { error: role.errors }, status: :unprocessable_content
      end
    end

    private

    def load_invitation
      @invitation = TeacherInvitation.find_by_token_for!(:teacher_invitation, params[:token])
    end

    def ensure_invitation_email_matches_user_email
      return if invitation_email_matches_user?

      render json: { error: 'Invitation email does not match user email' }, status: :forbidden
    end

    def authorize_invitation
      authorize! invitation_authorization_action, @invitation
    end

    def invitation_authorization_action
      action_name == 'accept' ? :accept : :read
    end

    def invitation_email_matches_user?
      current_user.email.present? &&
        @invitation.email_address.present? &&
        @invitation.email_address.casecmp?(current_user.email)
    end
  end
end
