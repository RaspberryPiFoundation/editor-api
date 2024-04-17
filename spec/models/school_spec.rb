# frozen_string_literal: true

require 'rails_helper'

RSpec.describe School do
  before do
    stub_user_info_api
  end

  describe 'associations' do
    it 'has many classes' do
      school = create(:school, classes: [build(:school_class), build(:school_class)])
      expect(school.classes.size).to eq(2)
    end

    it 'has many lessons' do
      school = create(:school, lessons: [build(:lesson), build(:lesson)])
      expect(school.lessons.size).to eq(2)
    end

    it 'has many projects' do
      school = create(:school, projects: [build(:project), build(:project)])
      expect(school.projects.size).to eq(2)
    end

    context 'when a school is destroyed' do
      let(:lesson1) { build(:lesson) }
      let(:lesson2) { build(:lesson) }
      let(:project) { build(:project) }

      let!(:school_class) { build(:school_class, members: [build(:class_member)], lessons: [lesson1]) }
      let!(:school) { create(:school, classes: [school_class], lessons: [lesson2], projects: [project]) }

      it 'also destroys school classes to avoid making them invalid' do
        expect { school.destroy! }.to change(SchoolClass, :count).by(-1)
      end

      it 'also destroys class members to avoid making them invalid' do
        expect { school.destroy! }.to change(ClassMember, :count).by(-1)
      end

      it 'does not destroy lessons' do
        expect { school.destroy! }.not_to change(Lesson, :count)
      end

      it 'nullifies school_id and school_class_id fields on lessons' do
        school.destroy!

        lessons = [lesson1, lesson2].map(&:reload)
        values = lessons.flat_map { |l| [l.school_id, l.school_class_id] }

        expect(values).to eq [nil, nil, nil, nil]
      end

      it 'does not destroy projects' do
        expect { school.destroy! }.not_to change(Project, :count)
      end

      it 'nullifies the school_id field on projects' do
        school.destroy!
        expect(project.reload.school_id).to be_nil
      end
    end
  end

  describe 'validations' do
    subject(:school) { build(:school) }

    it 'has a valid default factory' do
      expect(school).to be_valid
    end

    it 'can save the default factory' do
      expect { school.save! }.not_to raise_error
    end

    # The school's ID must be set before create from the profile app's organisation ID.
    # This avoids having two different IDs for a school which would be confusing.
    it 'requires an id' do
      school.id = ' '
      expect(school).to be_invalid
    end

    it 'requires a UUID id' do
      school.id = 'invalid'
      expect(school).to be_invalid
    end

    it 'requires a unique id' do
      create(:school)
      expect(school).to be_invalid
    end

    it 'requires a name' do
      school.name = ' '
      expect(school).to be_invalid
    end

    it 'does not require a reference' do
      create(:school, id: SecureRandom.uuid, reference: nil)

      school.reference = nil
      expect(school).to be_valid
    end

    it 'requires references to be unique if provided' do
      school.reference = 'URN-123'
      school.save!

      duplicate_school = build(:school, reference: 'urn-123')
      expect(duplicate_school).to be_invalid
    end

    it 'requires an address_line_1' do
      school.address_line_1 = ' '
      expect(school).to be_invalid
    end

    it 'requires a municipality' do
      school.municipality = ' '
      expect(school).to be_invalid
    end

    it 'requires a country_code' do
      school.country_code = ' '
      expect(school).to be_invalid
    end

    it "requires an 'ISO 3166-1 alpha-2' country_code" do
      school.country_code = 'GBR'
      expect(school).to be_invalid
    end
  end
end
