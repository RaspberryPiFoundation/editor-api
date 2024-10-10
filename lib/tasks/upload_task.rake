# frozen_string_literal: true

return unless Rails.env.development?

namespace :upload_job_test do
  desc 'Test trigger the UploadJob'
  task trigger: :environment do
    # Paste in a payload from the GitHub webhook (https://github.com/organizations/raspberrypilearning/settings/hooks)
    payload = {}

    abort('Stopping as no payload was provided (expects a payload from the GitHub webhook: https://github.com/organizations/raspberrypilearning/settings/hooks)') if payload.blank?

    if edited_code?(payload)
      UploadJob.perform_now(payload)
    else
      abort('Stopping as nothing under `/code` was edited in the push')
    end
  end

  def edited_code?(payload)
    commits = payload[:commits]
    modified_paths = commits.map { |commit| commit[:added] | commit[:modified] | commit[:removed] }.flatten
    modified_paths.count { |path| path.split('/')[1] == 'code' }.positive?
  end
end
