# frozen_string_literal: true

class TeacherInvitation < ApplicationRecord
  delegate :name, to: :school, prefix: true

  belongs_to :school
  validates :email_address,
            format: { with: EmailValidator.regexp, message: I18n.t('validations.invitation.email_address') }
  after_create_commit :send_invitation_email
  encrypts :email_address

  generates_token_for :teacher_invitation, expires_in: 30.days do
    email_address
  end

  private

  def send_invitation_email
    InvitationMailer.with(invitation: self).invite_teacher.deliver_later
  end
end
