# frozen_string_literal: true

require 'factory_bot'

Rails.logger = Logger.new(STDOUT)

def create_school(creator_id)
  School.find_or_create_by!(creator_id: creator_id) do |school|
    Rails.logger.info 'Seeding a school...'
    school.assign_attributes(FactoryBot.attributes_for(:school, creator_id: creator_id))
  end
end

def verify_school(school)
  SchoolVerificationService.new(school.id).verify
end

def create_school_class(teacher_id, school)
  SchoolClass.find_or_create_by!(teacher_id: teacher_id, school: school) do |school_class|
    Rails.logger.info 'Seeding a class...'
    school_class.assign_attributes(FactoryBot.attributes_for(:school_class, teacher_id: teacher_id, school: school))
  end
end

def create_lessons(user_id, school, school_class, visibility = "public")
  2.times.map do |i|
    Lesson.find_or_create_by!(school: school, school_class: school_class, description: "This is lesson #{i + 1}") do |lesson|
      Rails.logger.info "Seeding Lesson #{i + 1}..."
      lesson.assign_attributes(FactoryBot.attributes_for(
        :lesson,
        user_id: user_id,
        school: school,
        school_class: school_class,
        description: "This is lesson #{i + 1}",
        visibility: visibility
      ))
    end
  end
end

def create_project(user_id, school, lesson)
  Project.find_or_create_by!(user_id: user_id, school: school, lesson: lesson) do |project|
    Rails.logger.info "Seeding a project for #{lesson.name}..."
    project.assign_attributes(FactoryBot.attributes_for(:project, user_id: user_id, school: school, lesson: lesson))
  end
end

PROFILE_USERS = {
  jane: '583ba872-b16e-46e1-9f7d-df89d267550d', # jane.doe@example.com
  john: 'bbb9b8fd-f357-4238-983d-d6f87b99bdbb2'  # john.doe@example.com
}.freeze

if Rails.env.development? || Rails.env.staging?
  # These are static ids provided by staging profile (hard coded to avoid a dependency on profile)
  creator_id = PROFILE_USERS[:jane] # has owner & teacher roles
  # student_id = ENV['JOHN_DOE_USER_ID']

  Rails.logger.info "Attempting to seed data..."
  school = create_school(creator_id)
  verify_school(school) unless school.nil?

  school_class = create_school_class(creator_id, school)
  lessons = create_lessons(creator_id, school, school_class)
  lessons.each do |lesson|
    create_project(creator_id, school, lesson)
  end
  Rails.logger.info "Done..."
end
