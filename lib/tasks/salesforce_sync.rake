# frozen_string_literal: true

namespace :salesforce_sync do
  desc 'Sync all Schools to Salesforce'
  task school: :environment do
    School.find_each do |school|
      Salesforce::SchoolSyncJob.perform_later(school_id: school.id)
    end
  end

  desc 'Sync all non-student Roles to Salesforce'
  task role: :environment do
    Role.where.not(role: Role.roles[:student]).find_each do |role|
      Salesforce::RoleSyncJob.perform_later(role_id: role.id)
    end
  end

  desc 'Sync creator_agree_to_ux_contact for all Schools to Salesforce Contact'
  task contact: :environment do
    School.find_each do |school|
      Salesforce::ContactSyncJob.perform_later(school_id: school.id)
    end
  end
end
