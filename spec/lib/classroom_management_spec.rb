# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'classroom_management', type: :task do
  let(:creator_id) { '583ba872-b16e-46e1-9f7d-df89d267550d' } # jane.doe@example.com
  let(:teacher_id) { 'bbb9b8fd-f357-4238-983d-6f87b99bdbb2' } # john.doe@example.com

  describe ':destroy_seed_data' do
    let(:task) { Rake::Task['classroom_management:destroy_seed_data'] }
    let(:school) { create(:school, creator_id:) }

    before do
      create(:role, user_id: creator_id, school:)
      create(:teacher_role, user_id: creator_id, school:)
      create(:school_class, school_id: school.id, teacher_id: creator_id)
      create(:lesson, school_id: school.id, user_id: creator_id)
      create(:project, school_id: school.id, user_id: creator_id)
    end

    # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
    it 'destroys all seed data' do
      task.invoke
      expect(Role.where(user_id: creator_id)).not_to exist
      expect(School.where(creator_id:)).not_to exist
      expect(SchoolClass.where(school_id: school.id)).not_to exist
      expect(Lesson.where(school_id: school.id)).not_to exist
      expect(Project.where(school_id: school.id)).not_to exist
    end
    # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
  end

  describe ':seed_an_unverified_school' do
    let(:task) { Rake::Task['classroom_management:seed_an_unverified_school'] }

    it 'creates an unverified school' do
      task.invoke
      expect(School.find_by(creator_id:).verified_at).to be_nil
    end
  end

  describe ':seed_a_verified_school' do
    let(:task) { Rake::Task['classroom_management:seed_a_verified_school'] }

    it 'creates a verified school' do
      task.invoke
      expect(School.find_by(creator_id:).verified_at).to be_truthy
    end
  end

  describe ':seed_a_school_with_lessons' do
    let(:task) { Rake::Task['classroom_management:seed_a_school_with_lessons'] }

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
  end
end
