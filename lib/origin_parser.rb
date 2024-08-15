# frozen_string_literal: true

# fetch origins from the environment, these can be literal strings or regexes
# regexes must be wrapped in forward slashes eg. /https?:\/\/localhost(:[0-9]*)?$/
module OriginParser
  def self.parse_origins
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
