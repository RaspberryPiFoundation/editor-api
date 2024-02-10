# frozen_string_literal: true

class User
  include ActiveModel::Model

  ATTRIBUTES = %w[
    country
    country_code
    email
    email_verified
    id
    name
    nickname
    organisations
    picture
    postcode
    profile
  ].freeze

  attr_accessor(*ATTRIBUTES)

  def attributes
    ATTRIBUTES.index_with { |_k| nil }
  end

  def organisation_ids
    organisations.keys
  end

  def role?(organisation_id:, role:)
    roles = organisations[organisation_id.to_s]
    roles.to_s.split(',').map(&:strip).include?(role.to_s) if roles
  end

  def school_owner?(organisation_id:)
    role?(organisation_id:, role: 'school-owner')
  end

  def school_teacher?(organisation_id:)
    role?(organisation_id:, role: 'school-teacher')
  end

  def school_student?(organisation_id:)
    role?(organisation_id:, role: 'school-student')
  end

  def ==(other)
    id == other.id
  end

  def self.where(id:)
    from_userinfo(ids: id)
  end

  def self.from_userinfo(ids:)
    user_ids = Array(ids)

    UserinfoApiClient.fetch_by_ids(user_ids).map do |info|
      info = info.stringify_keys
      args = info.slice(*ATTRIBUTES)

      # TODO: remove once the UserinfoApi returns the 'organisations' key.
      temporarily_add_organisations_until_the_profile_app_is_updated(args)

      new(args)
    end
  end

  def self.from_omniauth(token:)
    return nil if token.blank?

    auth = HydraPublicApiClient.fetch_oauth_user(token:)
    return nil if auth.blank?

    auth = auth.stringify_keys
    args = auth.slice(*ATTRIBUTES)
    args['id'] ||= auth['sub']

    # TODO: remove once the HydraPublicApi returns the 'organisations' key.
    temporarily_add_organisations_until_the_profile_app_is_updated(args)

    new(args)
  end

  def self.temporarily_add_organisations_until_the_profile_app_is_updated(hash)
    return hash if hash.key?('organisations')

    # Use the same organisation ID as the one from users.json for now.
    hash.merge('organisations', { '12345678-1234-1234-1234-123456789abc' => hash['roles'] })
  end
end
