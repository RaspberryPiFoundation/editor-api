# frozen_string_literal: true

class Invitation < ApplicationRecord
  belongs_to :school
  validates :email_address,
            format: { with: EmailValidator.regexp, message: I18n.t('validations.invitation.email_address') }
end
