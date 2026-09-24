# frozen_string_literal: true

require 'faraday'

class RecordRequestHostInErrors < Faraday::Middleware
  module RequestHost
    attr_accessor :request_host
  end

  def call(env)
    super
  rescue Faraday::Error => e
    e.extend(RequestHost)
    e.request_host = env.url.host
    raise
  end
end
