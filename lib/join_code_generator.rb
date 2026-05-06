# frozen_string_literal: true

class JoinCodeGenerator
  # Removed letters that commonly form offensive words:
  # Removed vowels: None (need all 5 for readability)
  # Removed consonants: K (dick, fuck), X (sex), Z (rarely used anyway)
  CONSONANTS = %w[B C D F G H J L M N P Q R S T V W Y].freeze
  VOWELS = %w[A E I O U].freeze

  # Format: CVDDCVDD (e.g., CE18LI80)
  # C = Consonant, V = Vowel, D = Digit
  FORMAT_REGEX = /\A[A-Z][A-Z0-9]{7}\z/

  cattr_accessor :random

  self.random ||= Random.new

  # List of offensive letter patterns to avoid (consonant-vowel pairs)
  OFFENSIVE_PATTERNS = %w[
    AS BA BO BU DA DI FU HO PO SH TA TI VA
  ].freeze

  def self.generate
    max_attempts = 100
    max_attempts.times do
      code = [
        CONSONANTS.sample(random: random),
        VOWELS.sample(random: random),
        format('%02d', random.rand(100)),
        CONSONANTS.sample(random: random),
        VOWELS.sample(random: random),
        format('%02d', random.rand(100))
      ].join

      # Extract the CV patterns (positions 0-1 and 4-5)
      first_cv = code[0, 2]
      second_cv = code[4, 2]

      # Check if either CV pair matches offensive patterns
      next if OFFENSIVE_PATTERNS.include?(first_cv)
      next if OFFENSIVE_PATTERNS.include?(second_cv)

      return code
    end

    # Fallback if we couldn't generate a clean code after max_attempts
    raise 'Unable to generate non-offensive join code'
  end
end
