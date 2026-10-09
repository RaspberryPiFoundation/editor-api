# frozen_string_literal: true

module EditorApp
  # The editor web component reports an unloadable project through the
  # editor-projectLoadFailed event rather than an HTTP status, so it needs
  # somewhere to send the browser.
  class ErrorsController < ApplicationController
    skip_authorization_check

    def show
      render_not_found
    end
  end
end
