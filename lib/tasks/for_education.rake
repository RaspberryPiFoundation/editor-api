# frozen_string_literal: true

require_relative './seeds_helper'

Rails.logger = Logger.new($stdout) unless Rails.env.test?

# To override uuids call with:
# `SEEDING_CREATOR_ID=00000000-0000-0000-0000-000000000000 rails for_education:seed_an_unverified_school`
# `SEEDING_TEACHER_ID=00000000-0000-0000-0000-000000000000 rails for_education:seed_a_school_with_lessons`

# For students to match up the school needs to match with the school defined in profile (hard coded in the helper)

namespace :for_education do
  include SeedsHelper

  desc 'Destroy existing data'
  task destroy_seed_data: :environment do
    ActiveRecord::Base.transaction do
      Rails.logger.info 'Destroying existing seeds...'
      creator_id = ENV.fetch('SEEDING_CREATOR_ID', TEST_USERS[:jane_doe])
      teacher_id = ENV.fetch('SEEDING_TEACHER_ID', TEST_USERS[:john_doe])

      # Hard coded as the student's school needs to match
      student_ids = [TEST_USERS[:jane_smith], TEST_USERS[:john_smith]]
      school_id = TEST_SCHOOL

      # Remove the roles first
      Role.where(user_id: [creator_id, teacher_id] + student_ids).destroy_all

      # Destroy the project and then the lesson itself (The lesson's `before_destroy` prevents us using destroy)
      lesson_ids = Lesson.where(school_id:).pluck(:id)
      Project.where(lesson_id: [lesson_ids]).destroy_all
      Lesson.where(id: [lesson_ids]).delete_all

      # Destroy the class members and then the class itself
      school_class_ids = SchoolClass.where(school_id:).pluck(:id)
      ClassStudent.where(school_class_id: [school_class_ids]).destroy_all
      SchoolClass.where(id: [school_class_ids]).destroy_all

      # Destroy the school
      School.find(school_id).destroy

      Rails.logger.info 'Done...'
    rescue StandardError => e
      Rails.logger.error "Failed: #{e.message}"
      raise ActiveRecord::Rollback
    end
  end

  desc 'Create an unverified school'
  task seed_an_unverified_school: :environment do
    if School.find_by(code: TEST_SCHOOL)
      puts "Test school (#{TEST_SCHOOL}) already exists, run the destroy_seed_data task to start over)."
      return
    end

    ActiveRecord::Base.transaction do
      Rails.logger.info 'Attempting to seed data...'
      creator_id = ENV.fetch('SEEDING_CREATOR_ID', TEST_USERS[:jane_doe])
      create_school(creator_id, TEST_SCHOOL)

      Rails.logger.info 'Done...'
    rescue StandardError => e
      Rails.logger.error "Failed: #{e.message}"
      raise ActiveRecord::Rollback
    end
  end

  desc 'Create a verified school'
  task seed_a_verified_school: :environment do
    if School.find_by(code: TEST_SCHOOL)
      puts "Test school (#{TEST_SCHOOL}) already exists, run the destroy_seed_data task to start over)."
      return
    end

    ActiveRecord::Base.transaction do
      Rails.logger.info 'Attempting to seed data...'
      creator_id = ENV.fetch('SEEDING_CREATOR_ID', TEST_USERS[:jane_doe])

      school = create_school(creator_id, TEST_SCHOOL)
      verify_school(school)
      Rails.logger.info 'Done...'
    rescue StandardError => e
      Rails.logger.error "Failed: #{e.message}"
      raise ActiveRecord::Rollback
    end
  end

  desc 'Create a school with lessons and students'
  task seed_a_school_with_lessons_and_students: :environment do
    if School.find_by(code: TEST_SCHOOL)
      puts "Test school (#{TEST_SCHOOL}) already exists, run the destroy_seed_data task to start over)."
      return
    end

    ActiveRecord::Base.transaction do
      Rails.logger.info 'Attempting to seed data...'
      creator_id = ENV.fetch('SEEDING_CREATOR_ID', TEST_USERS[:jane_doe])
      teacher_id = ENV.fetch('SEEDING_TEACHER_ID', TEST_USERS[:john_doe])

      school = create_school(creator_id, TEST_SCHOOL)
      verify_school(school)
      assign_a_teacher(teacher_id, school)

      school_class = create_school_class(creator_id, school)
      assign_students(school_class, school)

      lessons = create_lessons(creator_id, school, school_class)
      lessons.each do |lesson|
        create_project(creator_id, school, lesson)
      end
      Rails.logger.info 'Done...'
    rescue StandardError => e
      Rails.logger.error "Failed: #{e.message}"
      raise ActiveRecord::Rollback
    end
  end
end
