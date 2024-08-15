# frozen_string_literal: true

class CorpMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)
    request_origin = env['HTTP_HOST']

    puts "Allowed origins: #{allowed_origins.to_json}"

    if env['PATH_INFO'].start_with?('/rails/active_storage') && allowed_origins.any? do |origin|
         origin.is_a?(Regexp) ? origin =~ request_origin : origin == request_origin
       end
      headers['Cross-Origin-Resource-Policy'] = 'cross-origin'
    end

    [status, headers, response]
  end

  def allowed_origins
    ENV['ALLOWED_ORIGINS']&.split(',')&.map do |origin|
      stripped_origin = origin.strip
      if stripped_origin.start_with?('/') && stripped_origin.end_with?('/')
        Regexp.new(stripped_origin[1..-2])
      else
        stripped_origin
      end
    end || []
  end
end
