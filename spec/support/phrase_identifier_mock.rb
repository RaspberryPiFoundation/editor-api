module PhraseIdentifierMock
  def mock_phrase_generation(phrase = nil)
    # This could cause problems if tests require multiple phrases to be generated
    phrase ||= "#{Faker::Verb.base}-#{Faker::Verb.base}-#{Faker::Verb.base}"

    allow(PhraseIdentifier).to receive(:generate).and_return(phrase)
  end
end
