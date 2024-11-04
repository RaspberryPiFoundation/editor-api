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
      school_class = create(:school_class, school_id: school.id, teacher_id: creator_id)
      create(:class_member, student_id: student_1, school_class_id: school_class.id)
      create(:lesson, school_id: school.id, user_id: creator_id)
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'destroys all seed data' do
      task.invoke
      expect(Role.where(user_id: [creator_id, teacher_id, student_1, student_2])).not_to exist
      expect(School.where(creator_id:)).not_to exist
      expect(ClassMember.where(student_id: student_1)).not_to exist
      expect(SchoolClass.where(school_id: school.id)).not_to exist
      expect(Lesson.where(school_id: school.id)).not_to exist
      expect(Project.where(school_id: school.id)).not_to exist
    end
    # rubocop:enable RSpec/MultipleExpectations
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

    before do
      task.invoke
    end

    it 'creates a verified school' do
      expect(School.find_by(creator_id:).verified_at).to be_truthy
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'creates lessons with projects' do
      school = School.find_by(creator_id:)
      expect(SchoolClass.where(school_id: school.id)).to exist
      lesson = Lesson.where(school_id: school.id)
      expect(lesson.length).to eq(2)
      expect(Project.where(lesson_id: lesson.pluck(:id)).length).to eq(2)
    end
    # rubocop:enable RSpec/MultipleExpectations

    it 'assigns a teacher' do
      school = School.find_by(creator_id:)
      expect(Role.teacher.where(user_id: teacher_id, school_id: school.id)).to exist
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'assigns students' do
      school_id = School.find_by(creator_id:).id
      school_class_id = SchoolClass.find_by(school_id:).id
      expect(Role.student.where(user_id: student_1, school_id:)).to exist
      expect(ClassMember.where(student_id: student_1, school_class_id:)).to exist
      expect(Role.student.where(user_id: student_2, school_id:)).to exist
      expect(ClassMember.where(student_id: student_2, school_class_id:)).to exist
    end
    # rubocop:enable RSpec/MultipleExpectations
  end
end
