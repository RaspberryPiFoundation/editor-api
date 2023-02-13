# frozen_string_literal: true

class GithubWebhooksController < ActionController::API
  include GithubWebhook::Processor

  def github_push(payload)
    UploadJob.perform_later if payload['ref'] == ENV.fetch('GITHUB_WEBHOOK_REF')
    head :ok
  end

  private

  def webhook_secret(_payload)
    ENV.fetch('GITHUB_WEBHOOK_SECRET')
  end
end
