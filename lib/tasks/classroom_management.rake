# frozen_string_literal: true

require_relative './classroom_management_helper'

Rails.logger = Logger.new($stdout) unless Rails.env.test?

# To override uuids call with:
# `SEEDING_CREATOR_ID=00000000-0000-0000-0000-000000000000 rails classroom_management:seed_an_unverified_school`
# `SEEDING_TEACHER_ID=00000000-0000-0000-0000-000000000000 rails classroom_management:seed_a_school_with_lessons`

# rubocop:disable Metrics/BlockLength
namespace :classroom_management do
  include ClassroomManagementHelper

  desc 'Destroy existing data'
  task destroy_seed_data: :environment do
    Rails.logger.info 'Destroying existing seeds...'
    creator_id = ENV.fetch('SEEDING_CREATOR_ID', TEST_USERS[:jane])
    teacher_id = ENV.fetch('SEEDING_TEACHER_ID', TEST_USERS[:john])
    school_id = ENV.fetch('SEEDING_SCHOOL_ID', School.find_by(creator_id:)&.id)

    Role.where(user_id: [creator_id, teacher_id]).destroy_all

    if school_id.nil? || creator_id.nil?
      Rails.logger.info 'No school found for creator, exiting...'
      exit
    end

    School.where(creator_id:).destroy_all
    SchoolClass.where(school_id:).destroy_all
    # The `before_destroy` on the Lesson model prevents us using destroy...so this is a soft deletion
    Lesson.where(school_id:).destroy_all
    Project.where(school_id:).destroy_all
    Rails.logger.info 'Done...'
  end

  desc 'Create an unverified school'
  task seed_an_unverified_school: :environment do
    Rails.logger.info 'Attempting to seed data...'
    creator_id = ENV.fetch('SEEDING_CREATOR_ID', TEST_USERS[:jane])
    create_school(creator_id)
    Rails.logger.info 'Done...'
  end

  desc 'Create a verified school'
  task seed_a_verified_school: :environment do
    Rails.logger.info 'Attempting to seed data...'
    creator_id = ENV.fetch('SEEDING_CREATOR_ID', TEST_USERS[:jane])
    school_id = ENV.fetch('SEEDING_SCHOOL_ID', nil)
    school = create_school(creator_id, school_id)
    verify_school(school)
    Rails.logger.info 'Done...'
  end

  desc 'Create a school with lessons'
  task seed_a_school_with_lessons: :environment do
    Rails.logger.info 'Attempting to seed data...'
    creator_id = ENV.fetch('SEEDING_CREATOR_ID', TEST_USERS[:jane])
    teacher_id = ENV.fetch('SEEDING_TEACHER_ID', TEST_USERS[:john])
    school_id = ENV.fetch('SEEDING_SCHOOL_ID', nil)

    school = create_school(creator_id, school_id)
    verify_school(school)
    assign_a_teacher(teacher_id, school)

    school_class = create_school_class(creator_id, school)
    lessons = create_lessons(creator_id, school, school_class)
    lessons.each do |lesson|
      create_project(creator_id, school, lesson)
    end
    Rails.logger.info 'Done...'
  end
end
# rubocop:enable Metrics/BlockLength
