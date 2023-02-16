# frozen_string_literal: true

class GithubWebhooksController < ActionController::API
  include GithubWebhook::Processor

  def github_push(payload)
    UploadJob.perform_later if payload[:ref] == ENV.fetch('GITHUB_WEBHOOK_REF') && edited_code?(payload)
    head :ok
  end

  private

  def webhook_secret(_payload)
    ENV.fetch('GITHUB_WEBHOOK_SECRET')
  end

  def edited_code?(payload)
    commits = payload[:commits]
    modified_paths = commits.map { |commit| commit[:added] | commit[:modified] | commit[:removed] }.flatten

    modified_code_paths = modified_paths.filter do |path|
      path_components = path.split('/')
      path_components[0] == 'en' && path_components[1] == 'code'
    end

    modified_code_paths.length.positive?
  end
end
