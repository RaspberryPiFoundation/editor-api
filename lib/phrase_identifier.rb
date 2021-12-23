# frozen_string_literal: true

class PhraseIdentifier
  def self.generate
    Word.order(Arel.sql('RANDOM()')).take(3).pluck(:word).join('-')
  end
end
