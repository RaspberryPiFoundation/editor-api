# frozen_string_literal: true

class FriendlyErrorMessagesInferenceClient
  class Error < StandardError; end

  MAX_COMPLETION_TOKENS = 300

  SYSTEM_PROMPT = Rails.root.join('config/friendly_error_messages_prompt.md').read

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
