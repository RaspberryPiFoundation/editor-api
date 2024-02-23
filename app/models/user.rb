# frozen_string_literal: true

class User
  include ActiveModel::Serialization
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
    token
    username
    roles
  ].freeze

  attr_accessor(*ATTRIBUTES)

  def attributes
    ATTRIBUTES.index_with { |_k| nil }
  end

  def organisation_ids
    organisations&.keys || []
  end

  def org_roles(organisation_id:)
    organisations[organisation_id.to_s]&.to_s&.split(',')&.map(&:strip) || []
  end

  def org_role?(organisation_id:, role:)
    org_roles(organisation_id:).include?(role.to_s)
  end

  def school_owner?(organisation_id:)
    org_role?(organisation_id:, role: 'school-owner')
  end

  def school_teacher?(organisation_id:)
    org_role?(organisation_id:, role: 'school-teacher')
  end

  def school_student?(organisation_id:)
    org_role?(organisation_id:, role: 'school-student')
  end

  def admin?
    organisation_ids.any? { |organisation_id| org_role?(organisation_id:, role: 'editor-admin') }
  end

  def ==(other)
    id == other.id
  end

  def self.where(id:)
    from_userinfo(ids: id)
  end

  def self.from_userinfo(ids:)
    user_ids = Array(ids)

    UserInfoApiClient.fetch_by_ids(user_ids).map do |info|
      info = info.stringify_keys
      args = info.slice(*ATTRIBUTES)

      # TODO: remove once the UserInfoApi returns the 'organisations' key.
      temporarily_add_organisations_until_the_profile_app_is_updated(args)

      new(args)
    end
  end

  def self.from_omniauth(auth = nil)
    return nil unless auth

    from_auth(auth)
  end

  def self.from_auth(auth)
    return nil unless auth

    args = auth.extra.raw_info.to_h.slice(*ATTRIBUTES)
    args['id'] = auth.uid

    new(args)
  end

  def self.from_token(token:)
    return nil if token.blank?

    auth = HydraPublicApiClient.fetch_oauth_user(token:)
    return nil if auth.blank?

    auth = auth.stringify_keys
    args = auth.slice(*ATTRIBUTES)

    args['id'] ||= auth['sub']
    args['token'] = token

    # TODO: remove once the HydraPublicApi returns the 'organisations' key.
    temporarily_add_organisations_until_the_profile_app_is_updated(args)

    new(args)
  end

  def self.temporarily_add_organisations_until_the_profile_app_is_updated(hash)
    return hash if hash.key?('organisations')

    # Use the same organisation ID as the one from users.json for now.
    hash.merge('organisations' => { '12345678-1234-1234-1234-123456789abc' => hash['roles'] })
  end
end
