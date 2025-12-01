# frozen_string_literal: true

require 'rails_helper'

RSpec.describe School do
  let(:student) { create(:student, school:) }
  let(:teacher) { create(:teacher, school:) }
  let(:school) { create(:school, creator_id: SecureRandom.uuid) }

  describe 'associations' do
    it 'has many classes' do
      create(:school_class, school:, teacher_ids: [teacher.id])
      create(:school_class, school:, teacher_ids: [teacher.id])
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
      let!(:school_class) { create(:school_class, school:, teacher_ids: [teacher.id]) }
      let!(:lesson_1) { create(:lesson, user_id: teacher.id, school_class:) }
      let!(:lesson_2) { create(:lesson, user_id: teacher.id, school:) }
      let!(:project) { create(:project, user_id: student.id, school:) }
      let!(:role) { create(:role, school:) }

      before do
        create(:class_student, school_class:, student_id: student.id)
      end

      it 'also destroys school classes to avoid making them invalid' do
        expect { school.destroy! }.to change(SchoolClass, :count).by(-1)
      end

      it 'also destroys class students to avoid making them invalid' do
        expect { school.destroy! }.to change(ClassStudent, :count).by(-1)
      end

      it 'also destroys class teachers to avoid making them invalid' do
        expect { school.destroy! }.to change(ClassTeacher, :count).by(-1)
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
      expect(school).not_to be_valid
    end

    it 'requires a website' do
      school.website = ' '
      expect(school).not_to be_valid
    end

    it 'requires a creator_id' do
      school.creator_id = nil
      expect(school).not_to be_valid
    end

    it 'requires a unique creator_id' do
      school.save!
      another_school = build(:school, creator_id: school.creator_id)
      another_school.valid?
      expect(another_school.errors[:creator_id]).to include('has already been taken')
    end

    it 'rejects a badly formed url for website' do
      school.website = 'http://.example.com'
      expect(school).not_to be_valid
    end

    it 'accepts a url with a multi-part TLD' do
      school.website = 'https://example.co.uk'
      expect(school).to be_valid
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
      expect(duplicate_school).not_to be_valid
    end

    it 'does not require a school_roll_number' do
      create(:school, id: SecureRandom.uuid, school_roll_number: nil)

      school.school_roll_number = nil
      expect(school).to be_valid
    end

    it 'requires school_roll_number to be unique if provided' do
      school.school_roll_number = '01572D'
      school.save!

      duplicate_school = build(:school, school_roll_number: '01572d')
      expect(duplicate_school).not_to be_valid
    end

    it 'accepts a valid alphanumeric school_roll_number' do
      school.school_roll_number = '01572D'
      expect(school).to be_valid
    end

    it 'accepts a school_roll_number with multiple letters' do
      school.school_roll_number = '12345ABC'
      expect(school).to be_valid
    end

    it 'rejects a school_roll_number with only numbers' do
      school.school_roll_number = '01572'
      expect(school).not_to be_valid
      expect(school.errors[:school_roll_number]).to include('must be alphanumeric (e.g., 01572D)')
    end

    it 'rejects a school_roll_number with only letters' do
      school.school_roll_number = 'ABCDE'
      expect(school).not_to be_valid
      expect(school.errors[:school_roll_number]).to include('must be alphanumeric (e.g., 01572D)')
    end

    it 'rejects a school_roll_number with special characters' do
      school.school_roll_number = '01572-D'
      expect(school).not_to be_valid
      expect(school.errors[:school_roll_number]).to include('must be alphanumeric (e.g., 01572D)')
    end

    it 'normalizes blank school_roll_number to nil' do
      school.school_roll_number = '  '
      expect(school).to be_valid
      expect(school.school_roll_number).to be_nil
    end

    it 'normalizes school_roll_number to uppercase' do
      school.school_roll_number = '01572d'
      expect(school).to be_valid
      expect(school.school_roll_number).to eq('01572D')
    end

    it 'requires an address_line_1' do
      school.address_line_1 = ' '
      expect(school).not_to be_valid
    end

    it 'requires a municipality' do
      school.municipality = ' '
      expect(school).not_to be_valid
    end

    it 'requires a country_code' do
      school.country_code = ' '
      expect(school).not_to be_valid
    end

    it "requires an 'ISO 3166-1 alpha-2' country_code" do
      school.country_code = 'GBR'
      expect(school).not_to be_valid
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
      expect(school).not_to be_valid
    end

    it 'requires creator_agree_terms_and_conditions to be true' do
      school.creator_agree_terms_and_conditions = false
      expect(school).not_to be_valid
    end

    it 'requires creator_agree_responsible_safeguarding to be true' do
      school.creator_agree_responsible_safeguarding = false
      expect(school).not_to be_valid
    end

    it 'does not require creator_agree_to_ux_contact to be true' do
      school.creator_agree_to_ux_contact = false
      expect(school).to be_valid
    end

    it 'cannot have #rejected_at set when #verified_at is present' do
      school.verify!
      school.reject
      expect(school.errors[:rejected_at]).to include('must be blank')
    end

    it 'cannot have #verified_at set when #rejected_at is present' do
      school.reject
      school.update(verified_at: Time.zone.now)
      expect(school.errors[:verified_at]).to include('must be blank')
    end

    it "cannot change #verified_at once it's been set" do
      school.verify!
      school.update(verified_at: nil)
      expect(school.errors[:verified_at]).to include('cannot be changed after verification')
    end

    it 'requires #code to be unique' do
      school.update!(code: '00-00-00', verified_at: Time.current)
      another_school = build(:school, code: '00-00-00')
      another_school.valid?
      expect(another_school.errors[:code]).to include('has already been taken')
    end

    it 'requires #code to be set when the school is verified' do
      school.update(verified_at: Time.current)
      expect(school.errors[:code]).to include("can't be blank")
    end

    it 'requires code to be blank until the school is verified' do
      school.update(code: 'school-code')
      expect(school.errors[:code]).to include('must be blank')
    end

    it 'requires code to be formatted as 3 pairs of digits separated by hyphens' do
      school.update(code: 'invalid', verified_at: Time.current)
      expect(school.errors[:code]).to include('is invalid')
    end

    it "cannot change #code once it's been set" do
      school.verify!
      school.update(code: '00-00-00')
      expect(school.errors[:code]).to include('cannot be changed after verification')
    end

    it 'requires a user_origin' do
      school.user_origin = nil
      expect(school).not_to be_valid
    end

    it 'sets the user_origin to for_education by default' do
      expect(school.user_origin).to eq('for_education')
    end
  end

  describe '#creator' do
    let(:creator) { create(:owner, school:) }

    before do
      school.update!(creator_id: creator.id)
      stub_user_info_api_for(creator)
    end

    it 'returns a User instance' do
      expect(school.creator).to be_instance_of(User)
    end

    it 'returns the creator from the UserInfo API matching the creator_id' do
      expect(school.creator.id).to eq(creator.id)
    end
  end

  describe '.find_for_user!' do
    before do
      stub_user_info_api_for(teacher)
    end

    it 'returns the school that the user has a role in' do
      user = User.where(id: teacher.id).first
      expect(described_class.find_for_user!(user)).to eq(school)
    end

    it "returns the school that the user created if they don't have a role in any school" do
      creator = create(:user)
      school.update!(creator_id: creator.id)
      expect(described_class.find_for_user!(creator)).to eq(school)
    end

    it "raises ActiveRecord::RecordNotFound if the user doesn't have a role in a school" do
      user = build(:user)
      expect { described_class.find_for_user!(user) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#verified?' do
    it 'returns true when verified_at is present' do
      school.verified_at = Time.zone.now
      expect(school).to be_verified
    end

    it 'returns false when verified_at is blank' do
      school.verified_at = nil
      expect(school).not_to be_verified
    end
  end

  describe '#rejected?' do
    it 'returns true when rejected_at is present' do
      school.rejected_at = Time.zone.now
      expect(school).to be_rejected
    end

    it 'returns false when rejected_at is blank' do
      school.rejected_at = nil
      expect(school).not_to be_rejected
    end
  end

  describe '#verify!' do
    it 'sets verified_at to the current time' do
      school.verify!
      expect(school.verified_at).to be_within(1.second).of(Time.zone.now)
    end

    it 'uses the school code generator to generates and set the code' do
      allow(ForEducationCodeGenerator).to receive(:generate).and_return('00-00-00')
      school.verify!
      expect(school.code).to eq('00-00-00')
    end

    it 'retries 5 times if the school code is not unique' do
      school.verify!
      allow(ForEducationCodeGenerator).to receive(:generate).and_return(school.code, school.code, school.code, school.code, '00-00-00')
      another_school = create(:school)
      another_school.verify!
      expect(another_school.code).to eq('00-00-00')
    end

    it 'raises exception if unique code cannot be generated in 5 retries' do
      school.verify!
      allow(ForEducationCodeGenerator).to receive(:generate).and_return(school.code, school.code, school.code, school.code, school.code)
      another_school = create(:school)
      expect { another_school.verify! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'returns true on successful verification' do
      expect(school.verify!).to be(true)
    end

    it 'raises ActiveRecord::RecordInvalid if verification fails' do
      school.rejected_at = Time.zone.now
      expect { school.verify! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '#format_uk_postal_code' do
    it 'retains correctly formatted UK postal_code' do
      school.country_code = 'GB'
      school.postal_code = 'SW1A 1AA'
      school.save
      expect(school.postal_code).to eq('SW1A 1AA')
    end

    it 'corrects incorrectly formatted UK postal_code' do
      school.country_code = 'GB'
      school.postal_code = 'SW1 A1AA'
      expect { school.save }.to change(school, :postal_code).to('SW1A 1AA')
    end

    it 'formats UK postal_code with 4 char outcode' do
      school.country_code = 'GB'
      school.postal_code = 'SW1A1AA'
      expect { school.save }.to change(school, :postal_code).to('SW1A 1AA')
    end

    it 'formats UK postal_code with 3 char outcode' do
      school.country_code = 'GB'
      school.postal_code = 'SW11AA'
      expect { school.save }.to change(school, :postal_code).to('SW1 1AA')
    end

    it 'formats UK postal_code with 2 char outcode' do
      school.country_code = 'GB'
      school.postal_code = 'SW1AA'
      expect { school.save }.to change(school, :postal_code).to('SW 1AA')
    end

    it 'does not format UK postal_code for short / invalid codes' do
      school.country_code = 'GB'
      school.postal_code = 'SW1A'
      expect { school.save }.not_to change(school, :postal_code)
    end

    it 'does not format postal_code for non-UK countries' do
      school.country_code = 'FR'
      school.postal_code = '123456'
      expect { school.save }.not_to change(school, :postal_code)
    end
  end

  describe '#reject' do
    it 'sets rejected_at to the current time' do
      school.reject
      expect(school.rejected_at).to be_within(1.second).of(Time.zone.now)
    end

    it 'returns true on successful rejection' do
      expect(school.reject).to be(true)
    end

    it 'returns false on unsuccessful rejection' do
      school.verified_at = Time.zone.now
      expect(school.reject).to be(false)
    end
  end

  describe '#reopen' do
    it 'sets rejected_at to nil' do
      school.reopen
      expect(school.rejected_at).to be_nil
    end

    it 'returns true on successful reopening' do
      expect(school.reopen).to be(true)
    end

    it 'returns false on unsuccessful reopening' do
      school.verified_at = Time.zone.now
      expect(school.reopen).to be(false)
    end
  end
end
