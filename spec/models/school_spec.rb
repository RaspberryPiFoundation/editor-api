# frozen_string_literal: true

require 'rails_helper'

RSpec.describe School do
  before do
    stub_user_info_api_for_teacher(teacher)
    stub_user_info_api_for_student(student)
  end

  let(:student) { create(:student, school:) }
  let(:teacher) { create(:teacher, school:) }
  let(:school) { create(:school, creator_id: SecureRandom.uuid) }

  describe 'associations' do
    it 'has many classes' do
      create(:school_class, school:, teacher_id: teacher.id)
      create(:school_class, school:, teacher_id: teacher.id)
      expect(school.classes.size).to eq(2)
    end

    it 'has many lessons' do
      create(:lesson, school:, user_id: teacher.id)
      create(:lesson, school:, user_id: teacher.id)
      expect(school.lessons.size).to eq(2)
    end

    it 'has many projects' do
      create(:project, user_id: student.id, school:)
      create(:project, user_id: student.id, school:)
      expect(school.projects.size).to eq(2)
    end

    it 'has many roles' do
      Role.delete_all
      create(:student_role, school:)
      create(:owner_role, school:)
      expect(school.roles.size).to eq(2)
    end

    context 'when a school is destroyed' do
      let!(:school_class) { create(:school_class, school:, teacher_id: teacher.id) }
      let!(:lesson_1) { create(:lesson, user_id: teacher.id, school_class:) }
      let!(:lesson_2) { create(:lesson, user_id: teacher.id, school:) }
      let!(:project) { create(:project, user_id: student.id, school:) }
      let!(:role) { create(:role, school:) }

      before do
        create(:class_member, school_class:, student_id: student.id)
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

      it 'does not destroy roles' do
        expect { school.destroy! }.not_to change(Role, :count)
      end

      it 'nullifies the school_id field on roles' do
        school.destroy!
        expect(role.reload.school_id).to be_nil
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

    it 'requires a creator_id' do
      school.creator_id = nil
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

    it 'does not require a creator_role' do
      school.creator_role = nil
      expect(school).to be_valid
    end

    it 'does not require a creator_department' do
      school.creator_department = nil
      expect(school).to be_valid
    end

    it 'requires creator_agree_authority to be true' do
      school.creator_agree_authority = false
      expect(school).to be_invalid
    end

    it 'requires creator_agree_terms_and_conditions to be true' do
      school.creator_agree_terms_and_conditions = false
      expect(school).to be_invalid
    end
  end

  describe '#creator' do
    let(:creator) { create(:owner, school:) }

    before do
      school.update!(creator_id: creator.id)
      stub_user_info_api_for_owner(creator)
    end

    it 'returns a User instance' do
      expect(school.creator).to be_instance_of(User)
    end

    it 'returns the creator from the UserInfo API matching the creator_id' do
      expect(school.creator.id).to eq(creator.id)
    end
  end

  describe '.find_for_user!' do
    it 'returns the school that the user has a role in' do
      user = User.where(id: teacher.id).first
      expect(described_class.find_for_user!(user)).to eq(school)
    end

    it "raises ActiveRecord::RecordNotFound if the user doesn't have a role in a school" do
      user = build(:user)
      expect { described_class.find_for_user!(user) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
