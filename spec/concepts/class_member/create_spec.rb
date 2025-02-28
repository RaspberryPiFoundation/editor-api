# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClassMember::Create, type: :unit do
  let(:token) { UserProfileMock::TOKEN }
  let!(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
  let(:school) { create(:school) }
  let(:students) { create_list(:student, 3, school:) }
  let(:teacher) { create(:teacher, school:) }

  let(:user_ids) { (students || []).map(&:id) }

  before do
    if students.present?
      student_attributes = students.map do |student|
        { id: student.id, name: student.name, username: student.username }
      end
    else
      student_attributes = nil
    end
    stub_profile_api_list_school_students(school:, student_attributes:)
    authenticated_in_hydra_as(teacher)
  end

  it 'returns a successful operation response' do
    response = described_class.call(school_class:, user_ids:, token:)
    expect(response.success?).to be(true)
  end

  it 'creates class students' do
    expect { described_class.call(school_class:, user_ids:, token:) }.to change(ClassStudent, :count).by(3)
  end

  it 'returns a class members JSON array' do
    response = described_class.call(school_class:, user_ids:, token:)
    expect(response[:class_members].size).to eq(3)
  end

  it 'returns class students in the operation response' do
    response = described_class.call(school_class:, user_ids:, token:)
    expect(response[:class_members]).to all(be_a(ClassStudent))
  end

  it 'assigns the school_class' do
    response = described_class.call(school_class:, user_ids:, token:)
    expect(response[:class_members]).to all(have_attributes(school_class:))
  end

  it 'assigns the student_id' do
    response = described_class.call(school_class:, user_ids:, token:)
    expect(response[:class_members].map(&:student_id)).to match_array(user_ids)
  end

  context 'when creations fail' do
    before do
      allow(Sentry).to receive(:capture_exception)
    end

    context 'with malformed students' do
      let(:students) { nil }

      it 'does not create a class member' do
        expect { described_class.call(school_class:, user_ids:, token:) }.not_to change(ClassStudent, :count)
      end

      it 'returns a failed operation response' do
        response = described_class.call(school_class:, user_ids:, token:)
        expect(response.failure?).to be(true)
      end

      it 'returns the error message in the operation response' do
        response = described_class.call(school_class:, user_ids:, token:)
        expect(response[:error]).to match(/No valid users provided/)
      end

      it 'sent the exception to Sentry' do
        described_class.call(school_class:, user_ids:, token:)
        expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
      end
    end

    context 'with a student from a different school' do
      let(:different_school) { create(:school) }
      let(:different_school_student) { create(:student, school: different_school) }

      context 'with non existent students' do
        let(:students) { [different_school_student] }

        it 'does not create a class member' do
          expect { described_class.call(school_class:, user_ids:, token:) }.not_to change(ClassStudent, :count)
        end

        it 'returns a successful operation response' do
          response = described_class.call(school_class:, user_ids:, token:)
          expect(response.success?).to be(true)
        end

        it 'returns an empty class members array' do
          response = described_class.call(school_class:, user_ids:, token:)
          expect(response[:class_members]).to eq([])
        end

        it 'returns the error messages in the operation response' do
          response = described_class.call(school_class:, user_ids:, token:)
          expect(response[:errors][different_school_student.id]).to include("Error creating class member for student #{different_school_student.id}: Student '#{different_school_student.id}' does not have the 'school-student' role for organisation '#{school.id}'")
        end

        it 'sent the exception to Sentry' do
          response = described_class.call(school_class:, user_ids:, token:)
          expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
        end
      end

      context 'when one creation fails' do
        let(:new_students) { students + [different_school_student] }
        let(:new_user_ids) { new_students.map(&:id) }

        it 'returns a successful operation response' do
          response = described_class.call(school_class:, user_ids: new_user_ids, token:)
          expect(response.success?).to be(true)
        end

        it 'returns a class members JSON array' do
          response = described_class.call(school_class:, user_ids: new_user_ids, token:)
          expect(response[:class_members].size).to eq(3)
        end

        it 'returns class members in the operation response' do
          response = described_class.call(school_class:, user_ids: new_user_ids, token:)
          expect(response[:class_members]).to all(be_a(ClassStudent))
        end

        it 'assigns the school_class' do
          response = described_class.call(school_class:, user_ids: new_user_ids, token:)
          expect(response[:class_members]).to all(have_attributes(school_class:))
        end

        it 'assigns the successful students' do
          response = described_class.call(school_class:, user_ids: new_user_ids, token:)
          expect(response[:class_members].map(&:student_id)).to match_array(user_ids)
        end

        it 'returns the error messages in the operation response' do
          response = described_class.call(school_class:, user_ids: new_user_ids, token:)
          expect(response[:errors][different_school_student.id]).to eq("Error creating class member for user #{different_school_student.id}: User '#{different_school_student.id}' does not have the 'school-teacher' or 'school-student' role for organisation '#{school.id}'")
        end
      end
    end
  end
end
