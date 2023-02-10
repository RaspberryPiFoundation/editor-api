# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Component do
  subject { build(:component) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:extension) }

  context 'when default component' do
    let(:component) { create(:default_python_component) }

    describe 'validations' do
      it 'returns valid? false when name changed' do
        component.name = 'updated'
        expect(component.valid?).to be(false)
      end

      it 'sets error message when name changed' do
        component.name = 'updated'
        component.valid?
        expect(component.errors[:name])
          .to include(I18n.t('errors.project.editing.change_default_name'))
      end

      it 'returns valid? false when extension changed' do
        component.extension = 'txt'
        expect(component.valid?).to be(false)
      end

      it 'sets error message when extension changed' do
        component.extension = 'txt'
        component.valid?
        expect(component.errors[:extension])
          .to include(I18n.t('errors.project.editing.change_default_extension'))
      end
    end
  end
end
