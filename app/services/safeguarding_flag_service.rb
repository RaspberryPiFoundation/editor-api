# frozen_string_literal: true

class SafeguardingFlagService
  class << self
    def create_for_school_roles(user:, school:)
      return if user.blank? || school.blank?

      roles = []
      roles << :teacher if user.school_teacher?(school)
      roles << :owner if user.school_owner?(school)

      create_for_roles(token: user.token, email: user.email, school:, roles:)
    end

    def create_for_token(token:, school:)
      return if token.blank? || school.blank?

      create_for_school_roles(user: user_for_token(token), school:)
    end

    def create_for_roles(token:, email:, school:, roles:)
      return if token.blank? || email.blank? || school.blank?

      Array(roles).each do |role|
        flag = ProfileApiClient::SAFEGUARDING_FLAGS[role.to_sym]
        next if flag.blank?

        ProfileApiClient.create_safeguarding_flag(
          token:,
          flag:,
          email:,
          school_id: school.id
        )
      end
    end

    private

    def user_for_token(token)
      cache = RequestStore.store[:safeguarding_flag_users_by_token] ||= {}
      return cache[token] if cache.key?(token)

      cache[token] = User.from_token(token:)
    end
  end
end
