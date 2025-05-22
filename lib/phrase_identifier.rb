# frozen_string_literal: true

class PhraseIdentifier
  PATTERN = /\A[a-z0-9]+(-[a-z0-9]+)*\z/

  class Error < RuntimeError
  end

  def self.generate
    10.times do
      phrase = words.shuffle.take(3).join('-')

      # Uh-oh, no words found?
      raise PhraseIdentifier::Error, 'Unable to generate a random phrase identifier' if phrase.blank?

      return phrase if unique?(phrase)
    end

    # Hmmm we've tried 10 times, so raise an exception.
    raise PhraseIdentifier::Error, 'Unable to generate a unique phrase identifier'
  end

  def self.unique?(phrase)
    phrase.present? && Project.where(identifier: phrase).none?
  end

  def self.words
    @words ||= File.readlines('words.txt', chomp: true)
  end
end
