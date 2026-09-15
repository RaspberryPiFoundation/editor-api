# frozen_string_literal: true

class OwnershipTransfer < ApplicationRecord
  delegate :name, to: :school, prefix: true

  belongs_to :school

  enum :status, {
    pre_pending: 'pre_pending', pending: 'pending',
    pre_completion: 'pre_completion', completed: 'completed',
    pre_rejected: 'pre_rejected', rejected: 'rejected',
    pre_cancelled: 'pre_cancelled', cancelled: 'cancelled'
  }, default: :pre_pending, validate: true

  validates :nominated_user_id, presence: true
  validates :requested_by_user_id, presence: true
  validates :email_address,
            format: { with: EmailValidator.regexp, message: I18n.t('validations.invitation.email_address') }
  validate :nominee_has_the_school_owner_or_school_teacher_role_for_the_school

  after_create_commit :send_ownership_transfer_request_email
  encrypts :email_address

  private

  def nominee_has_the_school_owner_or_school_teacher_role_for_the_school
    return unless nominated_user_id_changed? && errors.blank? && school

    nominated_user = User.from_userinfo(ids: [nominated_user_id]).first

    return if nominated_user.school_owner?(school)
    return if nominated_user.school_teacher?(school)

    msg = "'#{nominated_user_id}' does not have the 'owner' or 'teacher' role for school '#{school.id}'"
    errors.add(:nominated_user_id, msg)
  end

  def send_ownership_transfer_request_email
    SchoolOwnershipMailer.with(ownership_transfer: self).request_ownership_transfer.deliver_later
  end
end
