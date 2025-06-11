# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClassMember::List, type: :unit do
  let(:token) { UserProfileMock::TOKEN }
  let(:school) { create(:school) }
  let(:students) { create_list(:student, 3, school:) }
  let(:teacher) { create(:teacher, school:) }
  let(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
  let(:class_students) { school_class.students }

  let(:student_ids) { students.map(&:id) }
  let(:teacher_ids) { [teacher.id] }

  context 'with students and a teacher' do
    before do
      student_ids.each do |student_id|
        create(:class_student, school_class:, student_id:)
      end

      student_attributes = students.map do |student|
        { id: student.id, name: student.name, username: student.username }
      end
      stub_profile_api_list_school_students(school:, student_attributes:)
      stub_user_info_api_for(teacher)
    end

    it 'returns a successful operation response' do
      response = described_class.call(school_class:, class_students:, token:)
      expect(response.success?).to be(true)
    end

    it 'returns class members in the operation response' do
      response = described_class.call(school_class:, class_students:, token:)
      expect(response[:class_members].count { |member| member.is_a?(ClassStudent) }).to eq(3)
    end

    it 'returns the teacher in the operation response' do
      response = described_class.call(school_class:, class_students:, token:)
      expect(response[:class_members].count { |member| member.is_a?(User) }).to eq(1)
    end

    it 'contains the expected students' do
      response = described_class.call(school_class:, class_students:, token:)
      class_students.each do |class_student|
        expect(response[:class_members].map(&:id)).to include(class_student.id)
      end
    end

    it 'contains the expected teacher' do
      response = described_class.call(school_class:, class_students:, token:)
      expect(response[:class_members].map(&:id)).to include(teacher.id)
    end
  end

  context 'when errors occur' do
    before do
      allow(Sentry).to receive(:capture_exception)
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'captures and handles errors' do
      allow(SchoolStudent::List).to receive(:call).and_raise(StandardError.new('forced error'))

      response = described_class.call(school_class:, class_students:, token:)

      expect(response[:error]).to eq('Error listing class members: forced error')
      expect(Sentry).to have_received(:capture_exception).with(instance_of(StandardError))
    end
    # rubocop:enable RSpec/MultipleExpectations

    it 'returns an empty array when no ids match' do
      allow(SchoolStudent::List).to receive(:call).and_return({ school_students: [] })
      allow(SchoolTeacher::List).to receive(:call).and_return({ school_teachers: [] })

      response = described_class.call(school_class:, class_students:, token:)

      expect(response[:class_members]).to eq([])
    end
  end
end
