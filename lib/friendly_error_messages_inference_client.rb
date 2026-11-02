# frozen_string_literal: true

class FriendlyErrorMessagesInferenceClient
  class Error < StandardError; end

  SYSTEM_PROMPT_BASE = <<~PROMPT
    You help young people learn to program in Python.

    A learner will show you some Python code, and usually an error message. Respond with a
    short piece of feedback, addressed to them, that helps them find and fix the problem
    themselves.
  PROMPT

  SYSTEM_PROMPT_L1_EXPLAIN = <<~PROMPT
    The learner has only seen the raw Python error. Nothing has explained it to them yet.

    Say in plain language what the error means, and suggest which part of their code to
    look at. Pose it as a suggestion, not an instruction — "it might be worth checking…"
    rather than "change…".

    Three or four short sentences.

    Do not write any code in this reply. No code blocks and no corrected lines.
  PROMPT

  def initialize
    @client = OpenAI::Client.new(
      base_url: ENV.fetch('FEM_INFERENCE_API_URL'),
      api_key: ENV.fetch('FEM_INFERENCE_API_KEY'),
      timeout: 15.0,
      max_retries: 0
    )
  end

  def get_message(message, trace, runtime, code)
    return 'This is a placeholder friendly error message.' if ENV.fetch('BYPASS_FEM_INFERENCE', nil) == 'true'

    @client.responses.create(
      model: 'qwen3.5:9b',
      input: [
        { role: 'system', content: SYSTEM_PROMPT_BASE },
        { role: 'system', content: SYSTEM_PROMPT_L1_EXPLAIN },
        { role: 'user', content: JSON.dump({ message:, trace:, runtime:, code: }) }
      ],
      reasoning: { effort: :none }
    ).output_text
  rescue OpenAI::Errors::APIError => e
    raise Error, e.message
  end
end
