# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolMember::List, type: :unit do
  let(:token) { UserProfileMock::TOKEN }
  let(:school) { create(:school) }
  let(:students) { create_list(:student, 3, school:) }
  let(:teacher) { create(:teacher, school:) }

  let(:student_ids) { students.map(&:id) }
  let(:teacher_ids) { [teacher.id] }

  context 'with a mixture of students' do
    let(:sso_student) { create(:student, :sso, school:) }
    let(:standard_student) { create(:student, school:) }

    before do
      student_attributes = [
        { id: sso_student.id, name: sso_student.name, username: sso_student.username, email: sso_student.email },
        { id: standard_student.id, name: standard_student.name, username: standard_student.username, email: standard_student.email }
      ]
      stub_profile_api_list_school_students(school:, student_attributes:)
    end

    it 'returns a successful operation response' do
      response = described_class.call(school:, token:)
      expect(response.success?).to be(true)
    end

    it 'contains the expected students' do
      response = described_class.call(school:, token:)
      expect(response[:school_members].map(&:id)).to include(sso_student.id)
      expect(response[:school_members].map(&:id)).to include(standard_student.id)
    end

    it 'sets sso to true for SSO students (email present, username blank)' do
      response = described_class.call(school:, token:)
      school_members = response[:school_members]
      sso_member = school_members.find { |m| m.id == sso_student.id }

      expect(sso_member.sso).to be(true)
      expect(sso_member.email).to be_present
      expect(sso_member.username).to be_nil
      expect(sso_member.type).to eq(:student)
    end

    it 'sets sso to false for standard students (username present, email blank)' do
      response = described_class.call(school:, token:)
      school_members = response[:school_members]
      standard_member = school_members.find { |m| m.id == standard_student.id }

      expect(standard_member.sso).to be(false)
      expect(standard_member.email).to be_nil
      expect(standard_member.username).to be_present
      expect(standard_member.type).to eq(:student)
    end
  end

  context 'with teachers' do
    before do
      stub_user_info_api_for(teacher)
    end

    it 'contains the expected teacher' do
      response = described_class.call(school:, token:)
      expect(response[:school_members].map(&:id)).to include(teacher.id)
    end

    it 'sets sso to nil for teachers (not applicable)' do
      response = described_class.call(school:, token:)
      school_members = response[:school_members]
      teacher_member = school_members.find { |m| m.id == teacher.id }

      expect(teacher_member.sso).to be_nil
      expect(teacher_member.type).to eq(:teacher)
    end
  end

  context 'with owners' do
    let(:owner) { create(:owner, school:) }

    before do
      stub_user_info_api_for(owner)
    end

    it 'sets sso to nil for owners (not applicable)' do
      response = described_class.call(school:, token:)
      school_members = response[:school_members]
      owner_member = school_members.find { |m| m.id == owner.id }

      expect(owner_member.sso).to be_nil
      expect(owner_member.type).to eq(:owner)
    end
  end

  context 'when errors occur' do
    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'captures and handles errors' do
      allow(SchoolStudent::List).to receive(:call).and_raise(StandardError.new('forced error'))

      response = described_class.call(school:, token:)

      expect(response[:error]).to eq('Error listing school members: forced error')
      expect(Sentry).to have_received(:capture_exception).with(instance_of(StandardError))
    end

    it 'returns an empty array when no ids match' do
      allow(SchoolStudent::List).to receive(:call).and_return({ school_students: [] })
      allow(SchoolTeacher::List).to receive(:call).and_return({ school_teachers: [] })

      response = described_class.call(school:, token:)

      expect(response[:school_members]).to eq([])
    end
  end
end
