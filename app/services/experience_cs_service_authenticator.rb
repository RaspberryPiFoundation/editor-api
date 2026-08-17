# frozen_string_literal: true

class ExperienceCsServiceAuthenticator
  HEADER = 'X-Experience-CS-API-Key'
  USER_ID = '00000000-0000-0000-0000-000000000000'

  def self.authenticate(candidate)
    api_key = Rails.configuration.x.experience_cs.service_api_key
    return if api_key.blank? || candidate.blank?
    return unless ActiveSupport::SecurityUtils.secure_compare(candidate, api_key)

    User.new(id: USER_ID, roles: 'experience-cs-admin')
  end
end
