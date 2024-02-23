# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project do
  describe 'associations', :sample_words do
    it { is_expected.to belong_to(:school).optional(true) }
    it { is_expected.to belong_to(:lesson).optional(true) }
    it { is_expected.to belong_to(:parent).optional(true) }
    it { is_expected.to have_many(:remixes).dependent(:nullify) }
    it { is_expected.to have_many(:components) }
    it { is_expected.to have_many(:project_errors).dependent(:nullify) }
    it { is_expected.to have_many_attached(:images) }

    it 'purges attached images' do
      expect(described_class.reflect_on_attachment(:images).options[:dependent]).to eq(:purge_later)
    end
  end

  describe 'validations' do
    let(:project) { create(:project) }
    let(:identifier) { project.identifier }

    it 'is invalid if no user or locale' do
      invalid_project = build(:project, locale: nil, user_id: nil)
      expect(invalid_project).to be_invalid
    end

    it 'is valid if user but no locale' do
      valid_project = build(:project, locale: nil)
      expect(valid_project).to be_valid
    end

    context 'with same identifier and same user as existing project' do
      let(:user_id) { project.user_id }

      it 'is invalid if identifier in use by same user in the same locale' do
        new_project = build(:project, identifier:, user_id:, locale: project.locale)
        expect(new_project).to be_invalid
      end

      it 'is valid if identifier only in use by the user in the another locale' do
        new_project = build(:project, identifier:, user_id:, locale: 'another_locale')
        expect(new_project).to be_valid
      end
    end

    context 'with same identifier but different user as existing project' do
      let(:user_id) { 'another_user' }

      it 'is invalid if identifier in use by another user in same locale' do
        new_project = build(:project, identifier:, user_id:, locale: project.locale)
        expect(new_project).to be_invalid
      end

      it 'is invalid if identifier in use in another locale by another user' do
        new_project = build(:project, identifier:, user_id:, locale: 'another_locale')
        expect(new_project).to be_invalid
      end
    end
  end

  describe 'check_unique_not_null', :sample_words do
    let(:saved_project) { create(:project) }

    it 'generates an identifier if nil' do
      unsaved_project = build(:project, identifier: nil)
      expect { unsaved_project.valid? }.to change { unsaved_project.identifier.nil? }.from(true).to(false)
    end
  end
end
