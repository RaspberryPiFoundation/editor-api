# frozen_string_literal: true

class GenerateAiHintJob < ApplicationJob
  # How long editor-ui polls for a hint before giving up.
  UI_POLL_TIMEOUT = 30.seconds

  # A hint must leave enough time for inference to finish before editor-ui stops polling.
  MAX_QUEUE_WAIT = UI_POLL_TIMEOUT - FriendlyErrorMessagesInferenceClient::TIMEOUT

  queue_as :ai_hints

  def perform(ai_hint_id:)
    ai_hint = AiHint.find(ai_hint_id)
    return unless ai_hint.pending?
    return ai_hint.fail! if ai_hint.created_at < MAX_QUEUE_WAIT.ago

    input = ai_hint.input
    hint = FriendlyErrorMessagesInferenceClient.new.get_message(
      input['message'],
      input['trace'],
      input['runtime'],
      input['code']
    )

    ai_hint.complete!(hint)
  rescue FriendlyErrorMessagesInferenceClient::Error => e
    Sentry.capture_exception(e)
    ai_hint.fail!
  rescue StandardError
    # Don't leave the hint stuck in pending holding the input; re-raise so
    # GoodJob records the failure and sentry-rails reports it.
    ai_hint&.fail!
    raise
  end
end
