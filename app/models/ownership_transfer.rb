# frozen_string_literal: true

class OwnershipTransfer < ApplicationRecord
  delegate :name, to: :school, prefix: true

  belongs_to :school
  validates :email_address,
            format: { with: EmailValidator.regexp, message: I18n.t('validations.invitation.email_address') }
  after_create_commit :send_ownership_transfer_request_email
  encrypts :email_address

  generates_token_for :ownership_transfer, expires_in: 30.days do
    email_address
  end

  private

  def send_ownership_transfer_request_email
    SchoolOwnershipMailer.with(ownership_transfer: self).request_ownership_transfer.deliver_later
  end
end
