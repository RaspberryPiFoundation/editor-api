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

  desc 'Sync all SchoolClasses to Salesforce'
  task school_class: :environment do
    SchoolClass.find_each do |school_class|
      Salesforce::SchoolClassSyncJob.perform_later(school_class_id: school_class.id)
    end
  end

  desc 'Sync all ClassTeacher affiliations to Salesforce'
  task class_teacher: :environment do
    ClassTeacher.find_each do |class_teacher|
      Salesforce::ClassTeacherSyncJob.perform_later(class_teacher_id: class_teacher.id)
    end
  end

  desc 'Sync all classroom Lessons to Salesforce'
  task lesson: :environment do
    Lesson.where.not(school_class_id: nil).find_each do |lesson|
      Salesforce::LessonSyncJob.perform_later(lesson_id: lesson.id)
    end
  end
end
