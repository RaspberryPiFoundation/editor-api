# frozen_string_literal: true

module EditorApp
  module ApplicationHelper
    def code_classroom_url(path = '')
      "#{ENV.fetch('EDITOR_PUBLIC_URL', nil)}#{path}"
    end

    def projects_site_url(path)
      "https://projects.raspberrypi.org/#{Locale.projects_site(I18n.locale)}#{path}"
    end

    # Login happens in the host application, so :locale is cleared from the
    # engine's default_url_options to keep it out of host application paths.
    def editor_login_path(return_to:, login_options: nil)
      main_app.login_path({ returnTo: return_to, login_options: }.compact.merge(locale: nil))
    end

    def editor_logout_path
      main_app.logout_path(locale: nil)
    end

    def editor_login_authenticity_token
      form_authenticity_token(form_options: { action: main_app.login_path(locale: nil), method: 'post' })
    end
  end
end
