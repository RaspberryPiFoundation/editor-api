# frozen_string_literal: true

class ExperienceCsServiceAuthenticator
  HEADER = 'X-Experience-CS-API-Key'

  def self.authenticate(candidate)
    api_key = Rails.configuration.x.experience_cs.service_api_key
    return if api_key.blank? || candidate.blank?
    return unless ActiveSupport::SecurityUtils.secure_compare(candidate, api_key)

    User.new(id: User::EXPERIENCE_CS_SERVICE_ACCOUNT_ID, roles: 'experience-cs-admin')
  end
end
