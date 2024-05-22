# frozen_string_literal: true

require 'rails_helper'

RSpec.describe School do
  before do
    stub_user_info_api_for_teacher(teacher_id:, school_id: school.id)
    stub_user_info_api_for_student(student_id:, school_id: school.id)
  end

  let(:student_id) { SecureRandom.uuid }
  let(:teacher_id) { SecureRandom.uuid }
  let(:school) { create(:school) }

  describe 'associations' do
    it 'has many classes' do
      create(:school_class, school:, teacher_id:)
      create(:school_class, school:, teacher_id:)
      expect(school.classes.size).to eq(2)
    end

    it 'has many lessons' do
      create(:lesson, school:, user_id: teacher_id)
      create(:lesson, school:, user_id: teacher_id)
      expect(school.lessons.size).to eq(2)
    end

    it 'has many projects' do
      create(:project, user_id: student_id, school:)
      create(:project, user_id: student_id, school:)
      expect(school.projects.size).to eq(2)
    end

    context 'when a school is destroyed' do
      let!(:school_class) { create(:school_class, school:, teacher_id:) }
      let!(:lesson_1) { create(:lesson, user_id: teacher_id, school_class:) }
      let!(:lesson_2) { create(:lesson, user_id: teacher_id, school:) }
      let!(:project) { create(:project, user_id: student_id, school:) }

      before do
        create(:class_member, school_class:, student_id:)
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

      it 'nullifies school_id and school_class_id fields on lessons' do
        school.destroy!

        lessons = [lesson_1, lesson_2].map(&:reload)
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
    subject(:school) { create(:school) }

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
