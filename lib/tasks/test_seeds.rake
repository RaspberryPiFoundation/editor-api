# frozen_string_literal: true

require_relative 'seeds_helper'

# rubocop:disable Rails/Output
namespace :test_seeds do
  include SeedsHelper

  desc 'Destroy existing data'
  task destroy: :environment do
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
      pp "Failed: #{e.message}"
      Rails.logger.error "Failed: #{e.message}"
      raise ActiveRecord::Rollback
    end
  end

  desc 'Create a school with lessons and students'
  task create: :environment do
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

      # for each of the owner and teacher, create a class and assign students
      [creator_id, teacher_id].each do |user_id|
        teacher_name = user_id == creator_id ? 'Jane Doe' : 'John Doe'
        school_class = create_school_class(user_id, school, "#{teacher_name}'s Class", "A class for #{teacher_name}'s students")
        assign_students(school_class, school)

        lessons = create_lessons(user_id, school, school_class)
        lessons.each do |lesson|
          create_project(user_id, school, lesson, 'print("Hello World!")')
        end
      end
      Rails.logger.info 'Done...'
    rescue StandardError => e
      Rails.logger.error "Failed: #{e.message}"
      raise ActiveRecord::Rollback
    end
  end
end
# rubocop:enable Rails/Output
