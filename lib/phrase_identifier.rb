# frozen_string_literal: true

class PhraseIdentifier
  def self.generate
    phrase = Word.order(Arel.sql('RANDOM()')).take(3).pluck(:word).join('-') until unique?(phrase)
    phrase
  end

  private

  def self.unique?(phrase)
    !phrase.nil? && Project.find_by(identifier: phrase).nil?
  end
end
