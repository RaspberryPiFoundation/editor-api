# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:components) }
    it { is_expected.to have_many(:remixes).dependent(:nullify) }
    it { is_expected.to belong_to(:parent).optional(true) }
    it { is_expected.to have_many_attached(:images) }

    it 'purges attached images' do
      expect(described_class.reflect_on_attachment(:images).options[:dependent]).to eq(:purge_later)
    end
  end

  describe 'identifier not nil' do
    it 'generates an identifier if not present' do
      proj = build(:project, identifier: nil)
      expect { proj.valid? }
        .to change { proj.identifier.nil? }
        .from(true)
        .to(false)
    end
  end

  describe 'identifier unique' do
    it do
      project1 = create(:project)
      project2 = build(:project, identifier: project1.identifier)
      expect { project2.valid? }.to change(project2, :identifier)
    end
  end
end
