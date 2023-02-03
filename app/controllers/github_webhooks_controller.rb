class GithubWebhooksController < ActionController::API
  include GithubWebhook::Processor

  def github_push(payload)
    # TODO: handle push webhook
    head :ok
  end

  private

  def webhook_secret(payload)
    ENV['GITHUB_WEBHOOK_SECRET']
  end
end
