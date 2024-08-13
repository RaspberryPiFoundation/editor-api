# frozen_string_literal: true

class CorpMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)
    request_origin = env['HTTP_HOST']
    allowed_origins = ['staging-editor-api.raspberrypi.org', 'editor-api.raspberrypi.org']

    if env['PATH_INFO'].start_with?('/rails/active_storage') && allowed_origins.include?(request_origin)
      headers['Cross-Origin-Resource-Policy'] = 'cross-origin'
    end

    [status, headers, response]
  end
end
