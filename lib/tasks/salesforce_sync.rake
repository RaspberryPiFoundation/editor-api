# frozen_string_literal: true

namespace :salesforce_sync do
  desc 'Sync all Schools to Salesforce'
  task school: :environment do
    School.pluck(:id).each do |school_id|
      Salesforce::SchoolSyncJob.perform_later(school_id:)
    end
  end

  desc 'Sync all Roles to Salesforce'
  task role: :environment do
    Role.pluck(:id).each do |role_id|
      Salesforce::RoleSyncJob.perform_later(role_id:)
    end
  end

  desc 'Sync creator_agree_to_ux_contact for all Schools to Salesforce Contact'
  task contact: :environment do
    School.pluck(:id).each do |school_id|
      Salesforce::ContactSyncJob.perform_later(school_id:)
    end
  end
end
