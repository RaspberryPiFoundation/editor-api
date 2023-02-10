# frozen_string_literal: true

class GithubWebhooksController < ActionController::API
  include GithubWebhook::Processor

  def github_push(payload)
    if payload['ref'] == ENV.fetch('GITHUB_WEBHOOK_REF')
      UploadJob.perform_later
    end
    head :ok
  end

  private

  def webhook_secret(_payload)
    ENV.fetch('GITHUB_WEBHOOK_SECRET')
  end
end
