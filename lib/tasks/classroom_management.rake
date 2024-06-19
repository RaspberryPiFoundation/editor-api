# frozen_string_literal: true

require_relative './classroom_management_helper'

Rails.logger = Logger.new($stdout) unless Rails.env.test?

# rubocop:disable Metrics/BlockLength
namespace :classroom_management do
  include ClassroomManagementHelper

  desc 'Destroy existing data'
  task destroy_seed_data: :environment do
    Rails.logger.info 'Destroying existing seeds...'
    creator_id = TEST_USERS[:jane]
    Role.where(user_id: creator_id).destroy_all

    school_id = School.find_by(creator_id:)

    if school_id.nil? || creator_id.nil?
      Rails.logger.info 'No school found for creator, exiting...'
      exit
    end

    School.where(creator_id:).destroy_all
    SchoolClass.where(school_id:).destroy_all
    # The `before_destroy` on the Lesson model prevents us using destroy...this is permissable for seeded data only
    Lesson.where(school_id:).delete_all
    Project.where(school_id:).destroy_all
    Rails.logger.info 'Done...'
  end

  desc 'Create an unverified school'
  task seed_an_unverified_school: :environment do
    Rails.logger.info 'Attempting to seed data...'
    creator_id = TEST_USERS[:jane]
    create_school(creator_id)
    Rails.logger.info 'Done...'
  end

  desc 'Create a school with lessons'
  task seed_a_school_with_lessons: :environment do
    Rails.logger.info 'Attempting to seed data...'
    creator_id = TEST_USERS[:jane]
    school = create_school(creator_id)
    verify_school(school)
    assign_a_teacher(TEST_USERS[:john], school)
    school_class = create_school_class(creator_id, school)
    lessons = create_lessons(creator_id, school, school_class)
    lessons.each do |lesson|
      create_project(creator_id, school, lesson)
    end
    Rails.logger.info 'Done...'
  end
end
# rubocop:enable Metrics/BlockLength
