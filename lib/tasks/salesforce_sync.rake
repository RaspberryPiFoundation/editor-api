# frozen_string_literal: true

namespace :salesforce_sync do
  desc 'Sync all Schools to Salesforce'
  task school: :environment do
    School.pluck(:id).each do |school_id|
      Salesforce::SchoolSyncJob.perform_later(school_id:)
    end
  end
end
