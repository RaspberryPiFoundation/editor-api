# frozen_string_literal: true

module EditorApp
  class SessionRenewalComponent < BaseComponent
    attr_reader :user

    def initialize(user: nil)
      super()
      @user = user
    end

    def render?
      user.present?
    end

    def login_path
      editor_login_path(return_to: request.fullpath)
    end
  end
end
