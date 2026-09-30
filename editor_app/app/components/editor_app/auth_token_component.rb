# frozen_string_literal: true

module EditorApp
  class AuthTokenComponent < BaseComponent
    ELEMENT_ID = 'editor-app-auth-user'

    attr_reader :user, :expires_at

    delegate :auth_key, to: :EditorHydraClient

    def initialize(user: nil, expires_at: nil)
      super()
      @user = user
      @expires_at = expires_at
    end

    def stored_user
      {
        access_token: user.token,
        token_type: 'Bearer',
        scope: EditorHydraClient::SCOPE,
        expires_at:,
        profile: profile
      }.compact
    end

    private

    def profile
      {
        sub: user.sub,
        user: user.id,
        email: user.email,
        name: user.name,
        nickname: user.nickname,
        username: user.username,
        roles: user.roles
      }.compact
    end
  end
end
