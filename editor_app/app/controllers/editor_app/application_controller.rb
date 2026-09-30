# frozen_string_literal: true

module EditorApp
  class ApplicationController < ::ApplicationController
    layout 'editor_app/application'

    check_authorization

    around_action :switch_locale

    private

    def switch_locale(&)
      I18n.with_locale(requested_locale, &)
    end

    def requested_locale
      Locale.resolve(
        path: params[:locale],
        cookie: cookies[:i18next],
        accept_language: request.headers['Accept-Language']
      )
    end

    def default_url_options
      { locale: I18n.locale }
    end
  end
end
