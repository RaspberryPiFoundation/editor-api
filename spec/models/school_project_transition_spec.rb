# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolProjectTransition do
  describe 'associations' do
    it { is_expected.to belong_to(:school_project) }
  end

  describe 'after_destroy hook' do
    let(:school) { create(:school) }
    let(:student) { create(:student, school:) }
    let(:project) { create(:project, school: school, user_id: student.id) }
    let(:school_project) { create(:school_project, school: school, project: project) }

    it 'updates the most recent transition when the most recent is destroyed' do
      first_transition = described_class.create!(school_project:, from_state: 'unsubmitted', to_state: 'submitted', sort_key: 1, most_recent: false)
      most_recent_transition = described_class.create!(school_project:, from_state: 'submitted', to_state: 'complete', sort_key: 2, most_recent: true)

      most_recent_transition.destroy

      expect(first_transition.reload.most_recent).to be true
    end

    it 'does not update transitions when a non-most recent is destroyed' do
      most_recent_transition = described_class.create!(school_project:, from_state: 'unsubmitted', to_state: 'submitted', sort_key: 1, most_recent: true)
      non_most_recent_transition = described_class.create!(school_project:, from_state: 'submitted', to_state: 'complete', sort_key: 2, most_recent: false)

      non_most_recent_transition.destroy

      expect(most_recent_transition.reload.most_recent).to be true
    end
  end
end
