# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'for_education', type: :task do
  let(:creator_id) { '583ba872-b16e-46e1-9f7d-df89d267550d' } # jane.doe@example.com
  let(:teacher_id) { 'bbb9b8fd-f357-4238-983d-6f87b99bdbb2' } # john.doe@example.com
  let(:student_1) { 'e52de409-9210-4e94-b08c-dd11439e07d9' } # student
  let(:student_2) { '0d488bec-b10d-46d3-b6f3-4cddf5d90c71' } # student
  let(:school_id) { 'e52de409-9210-4e94-b08c-dd11439e07d9' }

  describe ':destroy_seed_data' do
    let(:task) { Rake::Task['for_education:destroy_seed_data'] }
    let(:school) { create(:school, creator_id:, id: school_id) }

    before do
      create(:role, user_id: creator_id, school:)
      create(:student_role, user_id: student_1, school:)
      create(:teacher_role, user_id: creator_id, school:)
      school_class = create(:school_class, school_id: school.id, teacher_ids: [creator_id])
      create(:class_student, student_id: student_1, school_class_id: school_class.id)
      create(:lesson, school_id: school.id, user_id: creator_id)
    end

    it 'destroys all seed data' do
      task.invoke
      expect(Role.where(user_id: [creator_id, teacher_id, student_1, student_2])).not_to exist
      expect(School.where(creator_id:)).not_to exist
      expect(ClassStudent.where(student_id: student_1)).not_to exist
      expect(SchoolClass.where(school_id: school.id)).not_to exist
      expect(ClassTeacher.where(teacher_id: creator_id)).not_to exist
      expect(Lesson.where(school_id: school.id)).not_to exist
      expect(Project.where(school_id: school.id)).not_to exist
    end
  end

  describe ':seed_an_unverified_school' do
    let(:task) { Rake::Task['for_education:seed_an_unverified_school'] }

    it 'creates an unverified school' do
      task.invoke
      expect(School.find_by(creator_id:).verified_at).to be_nil
    end
  end

  describe ':seed_a_verified_school' do
    let(:task) { Rake::Task['for_education:seed_a_verified_school'] }

    it 'creates a verified school' do
      task.invoke
      expect(School.find_by(creator_id:).verified_at).to be_truthy
    end
  end

  describe ':seed_a_school_with_lessons_and_students' do
    let(:task) { Rake::Task['for_education:seed_a_school_with_lessons_and_students'] }
    let(:school) { School.find_by(creator_id:) }

    before do
      Rake::Task['for_education:destroy_seed_data'].invoke
      task.invoke
    end

    it 'creates a verified school' do
      expect(school.verified_at).to be_truthy
    end

    it 'creates a school class' do
      expect(SchoolClass.where(school_id: school.id)).to exist
    end

    it 'adds two lessons to the school' do
      lesson = Lesson.where(school_id: school.id)
      expect(lesson.length).to eq(2)
    end

    it 'adds two projects' do
      lessons = Lesson.where(school_id: school.id)
      projects = Project.where(lesson_id: lessons.pluck(:id))

      if projects.length != 2
        $stdout.puts('Debug info for intermittent test')
        lessons.each { |lesson| $stdout.puts(lesson.inspect) }
        projects.each { |project| $stdout.puts(project.inspect) }
      end

      expect(projects.length).to eq(2)
    end

    it 'assigns a teacher' do
      expect(Role.teacher.where(user_id: teacher_id, school_id: school.id)).to exist
    end

    it 'creates a class teacher association for the creator' do
      expect(ClassTeacher.where(teacher_id: creator_id).length).to eq(1)
    end

    it 'assigns students' do
      school_id = school.id
      school_class_id = SchoolClass.find_by(school_id:).id
      expect(Role.student.where(user_id: student_1, school_id:)).to exist
      expect(ClassStudent.where(student_id: student_1, school_class_id:)).to exist
      expect(Role.student.where(user_id: student_2, school_id:)).to exist
      expect(ClassStudent.where(student_id: student_2, school_class_id:)).to exist
    end
  end
end
