# frozen_string_literal: true

require 'securerandom'

class JoinCodeGenerator
  # Omit K, X, Z — commonly confused or offensive in short codes.
  CONSONANTS = %w[B C D F G H J L M N P Q R S T V W Y].freeze

  # Format: CDDD-CDDD (e.g., B123-C456). C = consonant from CONSONANTS, D = digit.
  FORMAT_REGEX = Regexp.new("\\A(?:#{CONSONANTS.join('|')})\\d{3}-(?:#{CONSONANTS.join('|')})\\d{3}\\z").freeze

  def self.generate
    seg = lambda do
      consonant = CONSONANTS[SecureRandom.random_number(CONSONANTS.length)]
      "#{consonant}#{format('%03d', SecureRandom.random_number(1000))}"
    end

    "#{seg.call}-#{seg.call}"
  end

  # Canonical hyphenated form for DB lookup; accepts typed codes with or without a hyphen.
  def self.normalize(raw)
    alnum = raw.to_s.upcase.gsub(/[^A-Z0-9]/, '')
    return alnum if alnum.length != 8

    "#{alnum[0]}#{alnum[1, 3]}-#{alnum[4]}#{alnum[5, 3]}"
  end
end
