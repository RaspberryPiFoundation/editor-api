# frozen_string_literal: true

class Invitation < ApplicationRecord
  belongs_to :school
  validates :email_address,
            format: { with: EmailValidator.regexp, message: I18n.t('validations.invitation.email_address') }
  validate :school_is_verified
  after_create_commit :send_invitation_email

  private

  def school_is_verified
    return if school.verified_at

    errors.add(:school, 'is not verified')
  end

  def send_invitation_email
    InvitationMailer.with(invitation: self).invite_teacher.deliver_later
  end
end
