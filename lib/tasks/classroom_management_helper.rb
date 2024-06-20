# frozen_string_literal: true

require 'factory_bot'

module ClassroomManagementHelper
  TEST_USERS = {
    # Use this in conjunction with BYPASS_OAUTH=true to generate data for the bypass user
    bypass_oauth: '00000000-0000-0000-0000-000000000000',
    jane: '583ba872-b16e-46e1-9f7d-df89d267550d', # jane.doe@example.com
    john: 'bbb9b8fd-f357-4238-983d-6f87b99bdbb2' # john.doe@example.com
  }.freeze

  def create_school(creator_id, school_id = nil)
    School.find_or_create_by!(creator_id:, id: school_id) do |school|
      Rails.logger.info 'Seeding a school...'
      school.assign_attributes(FactoryBot.attributes_for(:school, creator_id:, id: school_id))
    end
  end

  def verify_school(school)
    Rails.logger.info 'Verifying the school...'
    SchoolVerificationService.new(school.id).verify
  end

  def create_school_class(teacher_id, school)
    SchoolClass.find_or_create_by!(teacher_id:, school:) do |school_class|
      Rails.logger.info 'Seeding a class...'
      school_class.assign_attributes(FactoryBot.attributes_for(:school_class, teacher_id:, school:))
    end
  end

  def assign_a_teacher(user_id, school)
    Rails.logger.info 'Adding a teacher...'
    Role.teacher.find_or_create_by!(user_id:, school:)
  end

  def create_lessons(user_id, school, school_class, visibility = 'public')
    2.times.map do |i|
      Lesson.find_or_create_by!(school:, school_class:,
                                description: "This is lesson #{i + 1}") do |lesson|
        Rails.logger.info "Seeding Lesson #{i + 1}..."
        lesson.assign_attributes(FactoryBot.attributes_for(
                                   :lesson,
                                   user_id:,
                                   school:,
                                   school_class:,
                                   description: "This is lesson #{i + 1}",
                                   visibility:
                                 ))
      end
    end
  end

  def create_project(user_id, school, lesson)
    Project.find_or_create_by!(user_id:, school:, lesson:) do |project|
      Rails.logger.info "Seeding a project for #{lesson.name}..."
      project.assign_attributes(FactoryBot.attributes_for(:project, user_id:, school:, lesson:))
    end
  end
end
