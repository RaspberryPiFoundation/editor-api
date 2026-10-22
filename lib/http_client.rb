# frozen_string_literal: true

require 'faraday'

module HttpClient
  def self.new(url = nil, options = {})
    Faraday.new(url, options) do |f|
      f.use RecordRequestHostInErrors
      yield f
    end
  end
end
