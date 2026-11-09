# frozen_string_literal: true

class FriendlyErrorMessagesInferenceClient
  class Error < StandardError; end

  MAX_COMPLETION_TOKENS = 300

  SYSTEM_PROMPT = <<~PROMPT
    You help young people learn to program in Python.

    A learner will show you some Python code, and usually an error message. Respond with a
    short piece of feedback, addressed to them, that helps them find and fix the problem
    themselves.
    The learner has only seen the raw Python error. Nothing has explained it to them yet.

    Say in plain language what the error means, and suggest which part of their code to
    look at. Pose it as a suggestion, not an instruction — "it might be worth checking…"
    rather than "change…".

    Three or four short sentences.

    Do not write any code in this reply. No code blocks and no corrected lines.
  PROMPT

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

    result
  rescue OpenAI::Errors::APIError => e
    raise Error, e.message
  end

  def build_request(message, trace, runtime, code)
    {
      model: '@cf/qwen/qwen3.8-27b',
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: JSON.dump({ message:, trace:, runtime:, code: }) }
      ],
      temperature: 0,
      max_completion_tokens: MAX_COMPLETION_TOKENS,

      request_options: {
        extra_headers: { 'cf-aig-gateway-id' => ENV.fetch('FEM_GATEWAY_NAME', '') },
        extra_body: { chat_template_kwargs: { enable_thinking: false } }
      }
    }
  end
end
