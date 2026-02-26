# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'school_management', type: :task do
  describe ':transfer_ownership' do
    let(:task) { Rake::Task['school_management:transfer_ownership'] }
    let(:old_user_id) { SecureRandom.uuid }
    let(:new_user_id) { SecureRandom.uuid }
    let(:school) { create(:school, creator_id: old_user_id) }

    before do
      stub_user_info_api_find_by_email(
        email: 'old_owner@example.com',
        user: { id: old_user_id, email: 'old_owner@example.com' }
      )

      stub_user_info_api_find_by_email(
        email: 'new_owner@example.com',
        user: { id: new_user_id, email: 'new_owner@example.com' }
      )

      create(:owner_role, school:, user_id: old_user_id)
      create(:teacher_role, school:, user_id: old_user_id)
    end

    it "exits early if new owner doesn't exist" do
      allow(UserInfoApiClient).to receive(:find_user_by_email)
        .with('not_real_owner@example.com')
        .and_return(nil)

      task.invoke('old_owner@example.com', 'not_real_owner@example.com')

      expect(school.creator_id).to eq(old_user_id)
    end

    it "exits early if old owner doesn't exist" do
      allow(UserInfoApiClient).to receive(:find_user_by_email)
        .with('not_real_owner@example.com')
        .and_return(nil)

      task.invoke('old_owner@example.com', 'new_owner@example.com')

      expect(school.creator_id).to eq(old_user_id)
    end

    it 'exits early if new owner is already owner of a school' do
      create(:owner_role, school:, user_id: new_user_id)

      task.invoke('old_owner@example.com', 'new_owner@example.com')

      expect(school.creator_id).to eq(old_user_id)
    end

    it 'exits early if new owner is already creator of a school' do
      create(:school, creator_id: new_user_id)

      task.invoke('old_owner@example.com', 'new_owner@example.com')

      expect(school.creator_id).to eq(old_user_id)
    end

    it 'creates owner and teacher roles for the new owner' do
      task.invoke('old_owner@example.com', 'new_owner@example.com')

      owners = school.roles.owner
      owner_user_ids = owners.map(&:user_id)
      teachers = school.roles.teacher
      teacher_user_ids = teachers.map(&:user_id)

      expect(owner_user_ids).to eq([new_user_id])
      expect(teacher_user_ids).to include(new_user_id)
    end

    it 'does not error if new owner already has teacher role' do
      create(:teacher_role, school:, user_id: new_user_id)
      task.invoke('old_owner@example.com', 'new_owner@example.com')

      owners = school.roles.owner
      owner_user_ids = owners.map(&:user_id)
      teachers = school.roles.teacher
      teacher_user_ids = teachers.map(&:user_id)

      expect(owner_user_ids).to eq([new_user_id])
      expect(teacher_user_ids).to include(new_user_id)
    end

    it 'keeps the old owner as a teacher if keep parameter is true' do
      task.invoke('old_owner@example.com', 'new_owner@example.com', 'true')
      teachers = school.roles.teacher
      teacher_user_ids = teachers.map(&:user_id)
      expect(teacher_user_ids).to include(old_user_id)
    end

    it 'removes the old owner as a teacher by default' do
      task.invoke('old_owner@example.com', 'new_owner@example.com')
      teachers = school.roles.teacher
      teacher_user_ids = teachers.map(&:user_id)
      expect(teacher_user_ids).not_to include(old_user_id)
    end

    it 'switches creator to the new owner' do
      task.invoke('old_owner@example.com', 'new_owner@example.com')
      school.reload
      expect(school.creator_id).to eq(new_user_id)
    end

    it 'sets the school UX contact flag to false' do
      school.update!(creator_agree_to_ux_contact: true)

      task.invoke('old_owner@example.com', 'new_owner@example.com')
      school.reload

      expect(school.creator_agree_to_ux_contact).to be(false)
    end
  end
end
