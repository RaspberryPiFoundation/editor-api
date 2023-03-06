# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project do
  describe 'associations' do
    it { is_expected.to have_many(:components) }
    it { is_expected.to have_many(:remixes).dependent(:nullify) }
    it { is_expected.to belong_to(:parent).optional(true) }
    it { is_expected.to have_many_attached(:images) }

    it 'purges attached images' do
      expect(described_class.reflect_on_attachment(:images).options[:dependent]).to eq(:purge_later)
    end
  end

  describe 'check_unique_not_null' do
    let(:saved_project) { create(:project) }

    it 'generates an identifier if nil' do
      unsaved_project = build(:project, identifier: nil)
      expect { unsaved_project.valid? }.to change { unsaved_project.identifier.nil? }.from(true).to(false)
    end

    it 'generates identifier if non-unique within locale' do
      invalid_project = build(:project, identifier: saved_project.identifier, locale: saved_project.locale)
      expect { invalid_project.valid? }.to change(invalid_project, :identifier)
    end

    it 'does not change identifier if duplicated in different locale' do
      valid_project = build(:project, identifier: saved_project.identifier, locale: 'ja-JP')
      expect { valid_project.valid? }.not_to change(valid_project, :identifier)
    end

    it 'changes indentifier if duplicated with nil locale' do
      user_project = build(:project, identifier: saved_project.identifier, locale: nil)
      expect { user_project.valid? }.to change(user_project, :identifier)
    end
  end
end
