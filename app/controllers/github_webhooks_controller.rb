# frozen_string_literal: true

class GithubWebhooksController < ActionController::API
  include GithubWebhook::Processor

  def github_push(payload)
    UploadJob.perform_later(payload) if payload[:ref] == webhook_ref && edited_code?(payload)
  end

  private

  def webhook_secret(_payload)
    Rails.configuration.x.github_webhook.secret
  end

  def webhook_ref
    ENV.fetch('GITHUB_WEBHOOK_REF')
  end

  def edited_code?(payload)
    commits = payload[:commits]
    modified_paths = commits.map { |commit| commit[:added] | commit[:modified] | commit[:removed] }.flatten
    modified_paths.count { |path| path.split('/')[1] == 'code' }.positive?
  end
end
