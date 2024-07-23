# frozen_string_literal: true

module ClassroomManagementHelper
  TEST_USERS = {
    # Use this in conjunction with BYPASS_OAUTH=true to generate data for the bypass user
    bypass_oauth: '00000000-0000-0000-0000-000000000000',
    jane_doe: '583ba872-b16e-46e1-9f7d-df89d267550d', # jane.doe@example.com
    john_doe: 'bbb9b8fd-f357-4238-983d-6f87b99bdbb2', # john.doe@example.com
    jane_smith: 'e52de409-9210-4e94-b08c-dd11439e07d9', # student
    john_smith: '0d488bec-b10d-46d3-b6f3-4cddf5d90c71' # student
  }.freeze

  TEST_SCHOOL = 'e52de409-9210-4e94-b08c-dd11439e07d9'

  def create_school(creator_id, school_id = nil)
    School.find_or_create_by!(creator_id:, id: school_id) do |school|
      Rails.logger.info 'Seeding a school...'
      school.name = 'Test School'
      school.website = 'http://example.com'
      school.address_line_1 = 'School Address'
      school.municipality = 'City'
      school.country_code = 'FR'
      school.creator_id = creator_id
      school.creator_agree_authority = true
      school.creator_agree_terms_and_conditions = true
      school.id = school_id if school_id
    end
  end

  def verify_school(school)
    Rails.logger.info 'Verifying the school...'
    school.verify!
    Role.owner.create!(user_id: school.creator_id, school:)
    Role.teacher.create!(user_id: school.creator_id, school:)
  end

  def create_school_class(teacher_id, school)
    SchoolClass.find_or_create_by!(teacher_id:, school:) do |school_class|
      Rails.logger.info 'Seeding a class...'
      school_class.name = 'Test Class'
      school_class.teacher_id = teacher_id
      school_class.school = school
    end
  end

  def assign_a_teacher(user_id, school)
    Rails.logger.info 'Adding a teacher...'
    Role.teacher.find_or_create_by!(user_id:, school:)
  end

  def assign_students(school_class, school)
    [TEST_USERS[:jane_smith], TEST_USERS[:john_smith]].map do |student_id|
      Rails.logger.info 'Assigning student role...'
      Role.student.find_or_create_by!(user_id: student_id, school:)

      ClassMember.find_or_create_by!(student_id:, school_class:) do |class_member|
        Rails.logger.info 'Adding student...'
        class_member.student_id = student_id
        class_member.school_class = school_class
      end
    end
  end

  # rubocop:disable Metrics/AbcSize
  def create_lessons(user_id, school, school_class, visibility = 'public')
    2.times.map do |i|
      Lesson.find_or_create_by!(school:, school_class:,
                                description: "This is lesson #{i + 1}") do |lesson|
        Rails.logger.info "Seeding Lesson #{i + 1}..."
        lesson.user_id = user_id
        lesson.school = school
        lesson.school_class = school_class
        lesson.name = "Test Lesson #{i + 1}"
        lesson.description = "This is lesson #{i + 1}"
        lesson.visibility = visibility
      end
    end
  end
  # rubocop:enable Metrics/AbcSize

  def create_project(user_id, school, lesson)
    Project.find_or_create_by!(user_id:, school:, lesson:) do |project|
      Rails.logger.info "Seeding a project for #{lesson.name}..."
      project.name = "Test Project for #{lesson.name}"
      project.user_id = user_id
      project.school = school
      project.lesson = lesson
      project.locale = 'en'
    end
  end
end
