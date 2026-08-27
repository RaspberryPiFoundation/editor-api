# frozen_string_literal: true

require 'rails_helper'

describe JoinStatusService do
  let(:school) { create(:school) }
  let(:school_class) { create(:school_class, school:) }
  let(:user) { build(:student, email: 'user@example.edu') }
  let(:service) { described_class.new(school:, school_class:, user:) }

  before do
    SchoolEmailDomain.create!(school:, domain: 'example.edu')
  end

  describe '#call' do
    context 'when the user is already a student of the class' do
      let(:user) { create(:student, school:) }

      before { ClassStudent.create!(school_class:, student_id: user.id) }

      it 'returns :already_member' do
        expect(service.call).to eq(:already_member)
      end
    end

    context 'when the user is already a teacher of the class' do
      let(:user) { create(:teacher, school:) }

      before { ClassTeacher.create!(school_class:, teacher_id: user.id) }

      it 'returns :already_member' do
        expect(service.call).to eq(:already_member)
      end
    end

    context 'when the user owns the school' do
      let(:user) { create(:user, email: 'user@example.edu') }

      before { create(:owner_role, school:, user_id: user.id) }

      it 'returns :owner' do
        expect(service.call).to eq(:owner)
      end
    end

    context 'when the user is a teacher of the school but not in this class' do
      let(:user) { create(:teacher, school:) }

      it 'returns :joinable_as_teacher' do
        expect(service.call).to eq(:joinable_as_teacher)
      end
    end

    context 'when the user is already a student of the school but not in this class' do
      let(:user) { create(:student, school:) }

      it 'returns :joinable' do
        expect(service.call).to eq(:joinable)
      end
    end

    context 'when the user has a non-student role in a different school' do
      let(:other_school) { create(:school) }
      let(:user) { create(:teacher, school: other_school) }

      it 'returns :not_a_student' do
        expect(service.call).to eq(:not_a_student)
      end
    end

    context 'when the user does not have a student account type' do
      let(:user) { build(:teacher, email: 'user@example.edu') }

      it 'returns :not_a_student' do
        expect(service.call).to eq(:not_a_student)
      end
    end

    context 'when the user is a student of a different school' do
      let(:other_school) { create(:school) }

      before { create(:student_role, school: other_school, user_id: user.id) }

      it 'returns :wrong_school' do
        expect(service.call).to eq(:wrong_school)
      end
    end

    context "when the user's email domain is not registered for the school" do
      let(:user) { build(:student, email: 'user@other.edu') }

      it 'returns :domain_mismatch' do
        expect(service.call).to eq(:domain_mismatch)
      end
    end

    context 'when the user has no prior role and their email domain matches the school' do
      it 'returns :joinable' do
        expect(service.call).to eq(:joinable)
      end
    end
  end
end
