# frozen_string_literal: true

require 'faraday'

module HttpClient
  def self.new(url = nil, options = {})
    default_options = {
      request: {
        read_timeout: 5,
        open_timeout: 5,
        write_timeout: 5,
        timeout: 10
      }
    }

    options = default_options.deep_merge(options)

    Faraday.new(url, options) do |f|
      f.use RecordRequestHostInErrors
      yield f
    end
  end
end
