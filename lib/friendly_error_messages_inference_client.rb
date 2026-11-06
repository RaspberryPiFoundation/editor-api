# frozen_string_literal: true

class FriendlyErrorMessagesInferenceClient
  class Error < StandardError; end

  MAX_RESULT_LENGTH_CHARS = 500
  MAX_COMPLETION_TOKENS = MAX_RESULT_LENGTH_CHARS * 0.66

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

  NO_REASONING_COMMAND = '/no_think'

  def initialize
    @client = OpenAI::Client.new(
      base_url: "#{ENV.fetch('FEM_INFERENCE_API_URL', '')}/ai/v1",
      api_key: ENV.fetch('FEM_INFERENCE_API_KEY', ''),
      timeout: 15.0,
      max_retries: 0
    )
  end

  def get_message(message, trace, runtime, code)
    return 'This is a placeholder friendly error message.' if ENV.fetch('BYPASS_FEM_INFERENCE', nil) == 'true'

    result = @client.chat.completions.create(
      build_request(message, trace, runtime, code)
    ).choices.first.message.content.to_s

    raise Error, 'No message returned by inference service.' if result.empty?
    raise Error, "The message by the inference service was too long - max #{MAX_RESULT_LENGTH_CHARS} chars, actual #{result.length} chars." if result.length > MAX_RESULT_LENGTH_CHARS

    result
  rescue OpenAI::Errors::APIError => e
    raise Error, e.message
  end

  def build_request(message, trace, runtime, code)
    {
      model: '@cf/qwen/qwen3-30b-a3b-fp8',
      messages: [
        { role: 'system', content: SYSTEM_PROMPT_BASE },
        { role: 'system', content: SYSTEM_PROMPT_L1_EXPLAIN },
        { role: 'system', content: NO_REASONING_COMMAND },
        { role: 'user', content: JSON.dump({ message:, trace:, runtime:, code: }) }
      ],
      temperature: 0,
      max_completion_tokens: MAX_COMPLETION_TOKENS,
      request_options: { extra_headers: { 'cf-aig-gateway-id' => ENV.fetch('FEM_GATEWAY_NAME', '') } }
    }
  end
end
