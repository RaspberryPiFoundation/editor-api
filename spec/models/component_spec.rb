# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Component, type: :model do
  subject { build(:component) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:extension) }
  it { is_expected.to validate_presence_of(:index) }
  it { is_expected.to validate_uniqueness_of(:index).scoped_to(:project_id) }

  context 'when default component' do
    let(:component) { create(:default_python_component) }

    describe 'validations' do
      it 'returns valid? false when name changed' do
        component.name = 'updated'
        expect(component.valid?).to eq(false)
      end

      it 'returns valid? false when extension changed' do
        component.extension = 'txt'
        expect(component.valid?).to eq(false)
      end
    end
  end
end
