# frozen_string_literal: true

class FriendlyErrorMessagesInferenceClient
  def initialize
    @client = OpenAI::Client.new(
      base_url: ENV.fetch('FEM_INFERENCE_API_URL'),
      api_key: ENV.fetch('FEM_INFERENCE_API_KEY')
    )
  end

  def get_message(message, trace, runtime, code)
    return 'This is a placeholder friendly error message.' if ENV.fetch('BYPASS_FEM_INFERENCE', nil) == 'true'

    @client.responses.create(model: 'qwen3.5:9b', input:
    JSON.dump({
                message:,
                trace:,
                runtime:,
                code:
              })).output_text
  end
end
