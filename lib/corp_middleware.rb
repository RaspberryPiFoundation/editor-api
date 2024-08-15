# frozen_string_literal: true

require_relative 'origin_parser'

class CorpMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)
    request_origin = env['HTTP_HOST']
    allowed_origins = OriginParser.parse_origins

    if env['PATH_INFO'].start_with?('/rails/active_storage') && allowed_origins.any? do |origin|
         origin.is_a?(Regexp) ? origin =~ request_origin : origin == request_origin
       end
      headers['Cross-Origin-Resource-Policy'] = 'cross-origin'
    end

    [status, headers, response]
  end
end
