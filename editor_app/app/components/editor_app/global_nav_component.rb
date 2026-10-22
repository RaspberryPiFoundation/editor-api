# frozen_string_literal: true

module EditorApp
  class GlobalNavComponent < BaseComponent
    VERSION = 'v1.8.9'
    SCRIPT_URL = "https://static.raspberrypi.org/js/global-nav-web-component/releases/#{VERSION}/rpf-global-nav.esm.js".freeze
    FORCE_SIGNUP = 'force_signup'
    LOCALE_PREFIX = %r{\A/[a-z]{2}(-[A-Z]{2})?(?=/|\z)}

    attr_reader :current_path, :signed_in, :student

    def initialize(current_path:, signed_in:, student: false)
      super()
      @current_path = current_path
      @signed_in = signed_in
      @student = student
    end

    def script_url
      SCRIPT_URL
    end

    def locales
      Locale::SELECTABLE.to_h { |locale, text| [locale, { url: path_in_locale(locale), text: }] }.to_json
    end

    def log_in_path
      editor_login_path(return_to: current_path)
    end

    def sign_up_path
      editor_login_path(return_to: current_path, login_options: FORCE_SIGNUP)
    end

    def log_out_path
      editor_logout_path
    end

    def authenticity_token
      editor_login_authenticity_token
    end

    private

    def path_in_locale(locale)
      remainder = current_path.sub(LOCALE_PREFIX, '')
      "/#{locale}#{remainder unless remainder == '/'}"
    end
  end
end
