# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Component, versioning: true do
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

    describe 'auditing' do
      let(:school) { create(:school) }
      let(:teacher) { create(:teacher, school:) }
      let(:student) { create(:student, school:) }

      it 'enables auditing for a component that belongs to a project with a school_id' do
        project_with_school = create(:project, user_id: student.id, school_id: school.id)
        component = create(:component, project: project_with_school)
        expect(component.versions.length).to(eq(1))
      end

      it 'does not enable auditing for a component that belongs to a project without a school_id' do
        project_without_school = create(:project, school_id: nil)
        component = create(:component, project: project_without_school)
        expect(project_without_school.versions.length).to(eq(0))
      end
    end
  end
end
