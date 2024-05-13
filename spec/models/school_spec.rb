# frozen_string_literal: true

require 'rails_helper'

RSpec.describe School do
  before do
    stub_user_info_api
  end

  describe 'associations' do
    it 'has many classes' do
      school = create(:school)
      create(:school_class, school:)
      create(:school_class, school:)

      expect(school.classes.size).to eq(2)
    end

    it 'has many lessons' do
      school = build(:school, lessons: [build(:lesson), build(:lesson)])
      expect(school.lessons.size).to eq(2)
    end

    it 'has many projects' do
      school = create(:school, projects: [build(:project), build(:project)])
      expect(school.projects.size).to eq(2)
    end

    context 'when a school is destroyed' do
      let(:school) { create(:school) }
      let(:project_name) { 'Project name' }
      let(:class_lesson_name) { 'Class lesson name' }
      let(:school_lesson_name) { 'School lesson name' }

      before do
        school_class = create(:school_class, school:)
        create(:class_member, school_class:)
        create(:lesson, name: class_lesson_name, school_class:, user_id: school_class.teacher_id)
        create(:lesson, name: school_lesson_name, school:)
        create(:project, name: project_name, school:)
      end

      it 'also destroys school classes to avoid making them invalid' do
        expect { school.destroy! }.to change(SchoolClass, :count).by(-1)
      end

      it 'also destroys class members to avoid making them invalid' do
        expect { school.destroy! }.to change(ClassMember, :count).by(-1)
      end

      it 'does not destroy lessons' do
        expect { school.destroy! }.not_to change(Lesson, :count)
      end

      it 'nullifies school_id on the lesson belonging to a class' do
        school.destroy!

        expect(Lesson.find_by(name: class_lesson_name).school_id).to be_nil
      end

      it 'nullifies school_id on the lesson belonging to a school' do
        school.destroy!

        expect(Lesson.find_by(name: school_lesson_name).school_id).to be_nil
      end

      it 'nullifies school_class_id on the lesson belonging to a class' do
        school.destroy!

        expect(Lesson.find_by(name: class_lesson_name).school_class_id).to be_nil
      end

      it 'nullifies school_class_id on the lesson belonging to a school' do
        school.destroy!

        expect(Lesson.find_by(name: school_lesson_name).school_class_id).to be_nil
      end

      it 'does not destroy projects' do
        expect { school.destroy! }.not_to change(Project, :count)
      end

      it 'nullifies the school_id field on projects' do
        school.destroy!

        expect(Project.find_by(name: project_name).school_id).to be_nil
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

    it 'requires a name' do
      school.name = ' '
      expect(school).to be_invalid
    end

    it 'requires a website' do
      school.website = ' '
      expect(school).to be_invalid
    end

    it 'rejects a badly formed url for website' do
      school.website = 'http://.example.com'
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
