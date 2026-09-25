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
      role = teacher_role
      return render json: { error: role.errors }, status: :unprocessable_content unless role.valid?

      Role.transaction do
        role.save!
        SafeguardingFlagService.create_for_school_roles(user: current_user, school: @invitation.school)
        @invitation.update!(accepted_at: Time.current) if @invitation.accepted_at.blank?
      end

      head :ok
    end

    private

    def teacher_role
      role = Role.unscoped.teacher.find_or_initialize_by(user_id: current_user.id, school: @invitation.school)
      role.archived_at = nil
      role
    end

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
