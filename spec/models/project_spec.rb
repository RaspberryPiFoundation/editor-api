# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project do
  subject { create(:project) }
  let(:invalid_project) { build(:project, identifier: subject.identifier, locale: subject.locale) }
  let(:valid_project) { build(:project, identifier: subject.identifier, locale: 'es-LA') }

  describe 'associations' do
    it { is_expected.to have_many(:components) }
    it { is_expected.to have_many(:remixes).dependent(:nullify) }
    it { is_expected.to belong_to(:parent).optional(true) }
    it { is_expected.to have_many_attached(:images) }

    it 'purges attached images' do
      expect(described_class.reflect_on_attachment(:images).options[:dependent]).to eq(:purge_later)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:identifier) }

    it 'validates uniqueness of identifier within locale' do
      expect(invalid_project).to be_invalid
    end

    it 'permits duplicate identifiers in different locales' do
      expect(valid_project).to be_valid
    end
  end

  describe 'check_unique_not_null' do
    it 'generates an identifier if nil' do
      unsaved_project = build(:project, identifier: nil)
      expect { unsaved_project.valid? }.to change { unsaved_project.identifier.nil? }.from(true).to(false)
    end

    it 'generates identifier if non-unique within locale' do
      expect { invalid_project.valid? }.to change(invalid_project, :identifier)
    end

    it 'does not change identifier if duplicated in different locale' do
      expect { valid_project.valid? }.not_to change(valid_project, :identifier)
    end
  end
end
