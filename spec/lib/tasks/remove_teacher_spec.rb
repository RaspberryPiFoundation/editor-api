# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'remove_teacher', type: :task do
  describe ':run' do
    let(:task) { Rake::Task['remove_teacher:run'] }
    let(:owner_id) { SecureRandom.uuid }
    let(:student_id) { SecureRandom.uuid }
    let(:school) { create(:school, creator_id: owner_id) }
    let(:teacher_id) { SecureRandom.uuid }

    before do
      stub_user_info_api_find_by_email(
        email: 'teacher@example.com',
        user: { id: teacher_id, email: 'teacher@example.com' }
      )

      stub_user_info_api_find_by_email(
        email: 'owner@example.com',
        user: { id: owner_id, email: 'owner@example.com' }
      )

      stub_user_info_api_find_by_email(
        email: 'student@example.com',
        user: { id: student_id, email: 'student@example.com' }
      )

      create(:teacher_role, school:, user_id: teacher_id)
      create(:owner_role, school:, user_id: owner_id)
      create(:student_role, school:, user_id: student_id)
    end

    it "exits early if the user doesn't exist" do
      # Arrange
      allow(UserInfoApiClient).to receive(:find_user_by_email)
        .with('not_real_teacher@example.com')
        .and_return(nil)

      # Act
      task.invoke('not_real_teacher@example.com')

      # assert
      expect(Role.find_by(user_id: teacher_id)).not_to be_nil
    end

    it 'exits early if the user has no teacher role' do
      # Act
      task.invoke('student@example.com')

      # Assert
      expect(Role.find_by(user_id: student_id)).not_to be_nil
    end

    it 'removes the role if it exists' do
      # Act
      task.invoke('teacher@example.com')

      # Assert
      expect(Role.find_by(user_id: teacher_id)).to be_nil
    end
  end
end
