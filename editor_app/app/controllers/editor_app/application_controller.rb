# frozen_string_literal: true

module EditorApp
  class ApplicationController < ::ApplicationController
    layout 'editor_app/application'

    check_authorization

    around_action :switch_locale

    helper_method :show_footer?

    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from CanCan::AccessDenied, with: :render_forbidden

    private

    def render_not_found
      render 'editor_app/errors/not_found', status: :not_found
    end

    def render_forbidden
      render 'editor_app/errors/forbidden', status: :forbidden
    end

    # The editor takes over the whole viewport, so its pages opt out.
    def show_footer?
      true
    end

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
