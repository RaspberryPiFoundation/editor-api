# frozen_string_literal: true

module SeedsHelper
  TEST_USERS = {
    jane_doe: '583ba872-b16e-46e1-9f7d-df89d267550d', # jane.doe@example.com
    john_doe: 'bbb9b8fd-f357-4238-983d-6f87b99bdbb2', # john.doe@example.com
    jane_smith: 'e52de409-9210-4e94-b08c-dd11439e07d9', # student
    john_smith: '0d488bec-b10d-46d3-b6f3-4cddf5d90c71' # student
  }.freeze

  # Match the school in profile...
  TEST_SCHOOL = 'e52de409-9210-4e94-b08c-dd11439e07d9' # e52de409-9210-4e94-b08c-dd11439e07d9
  SCHOOL_CODE = '12-34-56'

  def create_school(creator_id, school_id = nil)
    School.find_or_create_by!(creator_id:, id: school_id) do |school|
      Rails.logger.info 'Seeding a school...'
      school.name = Faker::Educator.secondary_school
      school.website = Faker::Internet.url(scheme: 'https')
      school.address_line_1 = Faker::Address.street_address
      school.municipality = Faker::Address.city
      school.country_code = Faker::Address.country_code
      school.creator_id = creator_id
      school.creator_agree_authority = true
      school.creator_agree_terms_and_conditions = true
      school.creator_agree_to_ux_contact = true
    end
  end

  def verify_school(school)
    if school.verified?
      Rails.logger.info "School #{school.code} is already verified."
      return
    end

    Rails.logger.info 'Verifying the school...'

    School.transaction do
      school.verify!
      Role.owner.create!(user_id: school.creator_id, school:)
      Role.teacher.create!(user_id: school.creator_id, school:)
    end

    # rubocop:disable Rails/SkipsModelValidations
    school.update_column(:code, SCHOOL_CODE) # The code needs to match the one in the profile
    # rubocop:enable Rails/SkipsModelValidations
  end

  def create_school_class(teacher_id, school, name = Faker::Educator.course_name, description = Faker::Hacker.phrases.sample)
    SchoolClass.joins(:class_teachers)
               .where(class_teachers: { teacher_id: }, school:)
               .first_or_create! do |school_class|
      Rails.logger.info 'Seeding a class...'
      school_class.name = name
      school_class.description = description
      # school_class.teacher_id = teacher_id
      school_class.school = school
      school_class.class_teachers = [ClassTeacher.new(teacher_id:)]
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

      ClassStudent.find_or_create_by!(student_id:, school_class:) do |class_student|
        Rails.logger.info 'Adding student...'
        class_student.student_id = student_id
        class_student.school_class = school_class
      end
    end
  end

  def create_lessons(user_id, school, school_class, visibility = 'students')
    2.times.map do |i|
      lesson_name = "Lesson #{i + 1}: #{Faker::ProgrammingLanguage.name}"
      Lesson.find_or_create_by!(school:, school_class:, name: lesson_name, user_id:) do |lesson|
        Rails.logger.info "Seeding Lesson #{i + 1}..."
        lesson.user_id = user_id
        lesson.school = school
        lesson.school_class = school_class
        lesson.name = lesson_name
        lesson.visibility = visibility
      end
    end
  end

  def create_project(user_id, school, lesson, code = '')
    Project.find_or_create_by!(user_id:, school:, lesson:) do |project|
      Rails.logger.info "Seeding a project for #{lesson.name}..."
      project.name = lesson.name
      project.user_id = user_id
      project.school = school
      project.lesson = lesson
      project.locale = 'en'
      project.project_type = 'python'
      project.components << Component.new({ extension: 'py', name: 'main',
                                            content: code })
    end
  end
end
