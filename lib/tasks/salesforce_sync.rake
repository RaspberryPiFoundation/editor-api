# frozen_string_literal: true

namespace :salesforce_sync do
  # Sync Schools to Salesforce that don't already exist there.
  # Usage:
  #   rake salesforce_sync:school          # Default: sync up to 25 records
  #   LIMIT=100 rake salesforce_sync:school # Sync up to 100 records
  #   LIMIT=0 rake salesforce_sync:school   # Sync all missing records (unlimited)
  desc 'Sync all Schools to Salesforce'
  task school: :environment do
    limit = ENV['LIMIT'] ? ENV['LIMIT'].to_i : 25
    limit = nil if limit.zero?
    enqueued = 0
    checked = 0

    School.find_each do |school|
      checked += 1
      unless Salesforce::School.exists?(editoruuid__c: school.id)
        Salesforce::SchoolSyncJob.perform_later(school_id: school.id)
        enqueued += 1
        break if limit && enqueued >= limit
      end
    end

    puts "Checked #{checked} schools, enqueued #{enqueued} jobs"
  end

  # Sync non-student Roles to Salesforce that don't already exist there.
  # Usage:
  #   rake salesforce_sync:role          # Default: sync up to 25 records
  #   LIMIT=100 rake salesforce_sync:role # Sync up to 100 records
  #   LIMIT=0 rake salesforce_sync:role   # Sync all missing records (unlimited)
  desc 'Sync all non-student Roles to Salesforce'
  task role: :environment do
    limit = ENV['LIMIT'] ? ENV['LIMIT'].to_i : 25
    limit = nil if limit.zero?
    enqueued = 0
    checked = 0

    Role.where.not(role: Role.roles[:student]).find_each do |role|
      checked += 1
      unless Salesforce::Role.exists?(affiliation_id__c: role.id)
        Salesforce::RoleSyncJob.perform_later(role_id: role.id)
        enqueued += 1
        break if limit && enqueued >= limit
      end
    end

    puts "Checked #{checked} roles, enqueued #{enqueued} jobs"
  end

  # Sync creator_agree_to_ux_contact for Schools where the Contact exists in Salesforce.
  # Usage:
  #   rake salesforce_sync:contact          # Default: sync up to 25 records
  #   LIMIT=100 rake salesforce_sync:contact # Sync up to 100 records
  #   LIMIT=0 rake salesforce_sync:contact   # Sync all records (unlimited)
  desc 'Sync creator_agree_to_ux_contact for all Schools to Salesforce Contact'
  task contact: :environment do
    limit = ENV['LIMIT'] ? ENV['LIMIT'].to_i : 25
    limit = nil if limit.zero?
    enqueued = 0
    checked = 0

    School.find_each do |school|
      checked += 1
      if Salesforce::Contact.exists?(pi_accounts_unique_id__c: school.creator_id)
        Salesforce::ContactSyncJob.perform_later(school_id: school.id)
        enqueued += 1
        break if limit && enqueued >= limit
      end
    end

    puts "Checked #{checked} schools, enqueued #{enqueued} contact sync jobs"
  end
end
