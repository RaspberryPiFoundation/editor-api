# frozen_string_literal: true

class Invitation < ApplicationRecord
  belongs_to :school
  validates :email_address,
            format: { with: EmailValidator.regexp, message: I18n.t('validations.invitation.email_address') }
  validate :school_is_verified

  private

  def school_is_verified
    return if school.verified_at

    errors.add(:school, 'is not verified')
  end
end
