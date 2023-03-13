# frozen_string_literal: true

class PhraseIdentifier
  class Error < RuntimeError
  end

  def self.generate
    10.times do
      phrase = Word.order(Arel.sql('RANDOM()')).take(3).pluck(:word).join('-')

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
end
