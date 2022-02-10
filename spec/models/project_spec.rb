# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:components) }
  end

  describe 'identifier not nil' do
    it 'generates an identifier if not present' do
      proj = FactoryBot.build(:project, identifier: nil)
      expect { proj.valid? }
        .to change { proj.identifier.nil? }
        .from(true)
        .to(false)
    end
  end

  describe 'identifier unique' do
    it do
      project1 = FactoryBot.create(:project)
      project2 = FactoryBot.build(:project, identifier: project1.identifier)
      expect { project2.valid? }.to change(project2, :identifier)
    end
  end
end
