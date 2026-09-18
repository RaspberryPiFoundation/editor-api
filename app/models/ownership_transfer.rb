# frozen_string_literal: true

class OwnershipTransfer < ApplicationRecord
  delegate :name, to: :school, prefix: true

  belongs_to :school

  enum :status, {
    pending: 'pending', completed: 'completed', rejected: 'rejected', cancelled: 'cancelled'
  }, default: :pending, validate: true

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

    return if school.roles.exists?(user_id: nominated_user_id, role: %i[owner teacher])

    msg = "'#{nominated_user_id}' does not have the 'owner' or 'teacher' role for school '#{school.id}'"
    errors.add(:nominated_user_id, msg)
  end

  def send_ownership_transfer_request_email
    SchoolOwnershipMailer.with(ownership_transfer: self).request_ownership_transfer.deliver_later
  end
end
