# frozen_string_literal: true

module EditorApp
  module ApplicationHelper
    def code_classroom_url(path = '')
      "#{ENV.fetch('EDITOR_PUBLIC_URL', nil)}#{path}"
    end

    def projects_site_url(path)
      "https://projects.raspberrypi.org/#{Locale.projects_site(I18n.locale)}#{path}"
    end

    # The engine adds :locale to default_url_options for its own routes, so it
    # has to be cleared when generating host application routes.
    def login_path(return_to:)
      main_app.login_path(returnTo: return_to, locale: nil)
    end

    def logout_path
      main_app.logout_path(locale: nil)
    end
  end
end
