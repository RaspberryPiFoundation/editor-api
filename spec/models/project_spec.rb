require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:components) }
  end

  context 'not null' do
    subject { Project.new }
    it { should validate_uniqueness_of(:identifier) }
  end
end
