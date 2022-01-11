# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:components) }
  end

  describe 'identifier not nil' do
    subject { FactoryBot.build(:project) }
    it { is_expected.not_to allow_value(nil).for(:identifier)}
  end

  describe 'identifier unique' do
    it do
      project1=FactoryBot.build(:project)
      project1.save
      project2=FactoryBot.build(:project, identifier: project1.identifier)
      expect {project2.valid?}.to change {project2.identifier}
    end
  end
end
