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

  def schools
    School.joins(:roles).merge(Role.where(user_id: id)).distinct
  end

  def school_roles(school)
    Role.where(school:, user_id: id).map(&:role)
  end

  def school_owner?(school)
    Role.owner.find_by(school:, user_id: id)
  end

  def school_teacher?(school)
    Role.teacher.find_by(school:, user_id: id)
  end

  def school_student?(school)
    Role.student.find_by(school:, user_id: id)
  end

  def student?
    Role.student.exists?(user_id: id)
  end

  def admin?
    (roles&.to_s&.split(',')&.map(&:strip) || []).include?('editor-admin')
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
    args['token'] = auth.credentials&.token

    new(args)
  end

  def self.from_token(token:)
    return nil if token.blank?

    auth = HydraPublicApiClient.fetch_oauth_user(token:)
    return nil if auth.blank?

    auth = auth.stringify_keys
    args = auth.slice(*ATTRIBUTES)

    args['id'] ||= auth['sub'].sub('student:', '')
    args['token'] = token

    new(args)
  end
end
