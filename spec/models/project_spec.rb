# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:components) }
  end

  describe 'identifier not nil' do
    subject { Project.new }
    it { is_expected.not_to allow_value(nil).for(:identifier)}
  end

  describe 'identifier unique' do
    before {FactoryBot.build(:project)}
    it {should validate_uniqueness_of(:identifier)}
  end
end
