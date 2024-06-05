# frozen_string_literal: true

class Invitation < ApplicationRecord
  belongs_to :school
  validate :email_is_valid

  private

  def email_is_valid
    return if EmailValidator.valid?(email_address)

    errors.add(:email_address, "'#{email_address}' is invalid")
  end
end
