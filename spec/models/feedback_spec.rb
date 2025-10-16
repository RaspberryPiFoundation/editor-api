# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Feedback do
  before do
    stub_user_info_api_for(teacher)
  end

  let(:teacher) { create(:teacher, school:, name: 'School Teacher') }
  let(:school) { create(:school) }

  describe 'associations' do
    it { is_expected.to belong_to(:school_project) }
  end

  describe 'validations', versioning: true do
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_presence_of(:user_id) }

    it 'validates that the user has the school-owner or school-teacher role for the school' do
      feedback = build(:feedback, user_id: SecureRandom.uuid)
      expect(feedback).not_to be_valid
      expect(feedback.errors[:user]).to include(/does not have the 'school-owner' or 'school-teacher' role/)
    end

    it 'validates that the parent project belongs to a lesson' do
      school_project = create(:school_project, school:, project: create(:project))
      feedback = build(:feedback, school_project:, user_id: teacher.id)
      expect(feedback).not_to be_valid
      expect(feedback.errors[:user]).to include(/Parent project '.*' does not belong to a 'lesson'/)
    end

    it 'validates that the parent project belongs to a school class' do
      parent_project = create(:project, user_id: teacher.id, school:, lesson: create(:lesson, school:, user_id: teacher.id))
      school_project = create(:school_project, school:, project: create(:project, parent: parent_project))
      feedback = build(:feedback, school_project:, user_id: teacher.id)
      expect(feedback).not_to be_valid
      expect(feedback.errors[:user]).to include(/Parent project '.*' does not belong to a 'school-class'/)
    end

    it 'validates that the user is the class teacher for the school project' do
      school_class = create(:school_class, teacher_ids: [teacher.id], school:)
      parent_project = create(:project, user_id: teacher.id, school:, lesson: create(:lesson, school:, school_class:, user_id: teacher.id))
      school_project = create(:school_project, school:, project: create(:project, parent: parent_project))
      other_teacher = create(:teacher, school:)
      feedback = build(:feedback, school_project:, user_id: other_teacher.id)
      expect(feedback).not_to be_valid
      expect(feedback.errors[:user]).to include(/is not the 'school-teacher' for school_project/)
    end

    it 'has a valid default factory' do
      feedback = build(:feedback)
      expect(feedback).to be_valid
    end
  end
end
