# frozen_string_literal: true

class GithubWebhooksController < ActionController::API
  include GithubWebhook::Processor

  def github_push(payload)
    UploadJob.perform_later(payload) if payload[:ref] == ENV.fetch('GITHUB_WEBHOOK_REF') && edited_code?(payload)
  end

  private

  def webhook_secret(_payload)
    ENV.fetch('GITHUB_WEBHOOK_SECRET')
  end

  def edited_code?(payload)
    commits = payload[:commits]
    modified_paths = commits.map { |commit| commit[:added] | commit[:modified] | commit[:removed] }.flatten
    modified_paths.count { |path| path.start_with?('en/code') }.positive?
  end
end
