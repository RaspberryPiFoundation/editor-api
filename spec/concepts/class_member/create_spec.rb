# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClassMember::Create, type: :unit do
  let!(:school_class) { create(:school_class, teacher_id: teacher.id, school:) }
  let(:school) { create(:school) }
  let(:students) { create_list(:student, 3, school:) }
  let(:teacher) { create(:teacher, school:) }

  let(:student_ids) { students.map(&:id) }

  it 'returns a successful operation response' do
    response = described_class.call(school_class:, students:)
    expect(response.success?).to be(true)
  end

  it 'creates a school class' do
    expect { described_class.call(school_class:, students:) }.to change(ClassMember, :count).by(3)
  end

  it 'returns a class members JSON array' do
    response = described_class.call(school_class:, students:)
    expect(response[:class_members].size).to eq(3)
  end

  it 'returns class members in the operation response' do
    response = described_class.call(school_class:, students:)
    expect(response[:class_members]).to all(be_a(ClassMember))
  end

  it 'assigns the school_class' do
    response = described_class.call(school_class:, students:)
    expect(response[:class_members]).to all(have_attributes(school_class:))
  end

  it 'assigns the student_id' do
    response = described_class.call(school_class:, students:)
    expect(response[:class_members].map(&:student_id)).to match_array(student_ids)
  end

  context 'when creations fail' do
    before do
      allow(Sentry).to receive(:capture_exception)
    end

    context 'with malformed students' do
      let(:students) { nil }

      it 'does not create a class member' do
        expect { described_class.call(school_class:, students:) }.not_to change(ClassMember, :count)
      end

      it 'returns a failed operation response' do
        response = described_class.call(school_class:, students:)
        expect(response.failure?).to be(true)
      end

      it 'returns the error message in the operation response' do
        response = described_class.call(school_class:, students:)
        expect(response[:error]).to match(/No valid students provided/)
      end

      it 'sent the exception to Sentry' do
        described_class.call(school_class:, students:)
        expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
      end
    end

    context 'with a student from a different school' do
      let(:different_school) { create(:school) }
      let(:new_student) { create(:student, school: different_school) }
      let(:failed_student_id) { new_student.id }

      context 'with non existent students' do
        let(:students) { [new_student] }

        it 'does not create a class member' do
          expect { described_class.call(school_class:, students:) }.not_to change(ClassMember, :count)
        end

        it 'returns a successful operation response' do
          response = described_class.call(school_class:, students:)
          expect(response.success?).to be(true)
        end

        it 'returns a successful operation response' do
          response = described_class.call(school_class:, students:)
          expect(response[:class_members]).to eq([])
        end

        it 'returns the error messages in the operation response' do
          response = described_class.call(school_class:, students:)
          expect(response[:errors][new_student.id]).to include("Error creating class member for student_id #{new_student.id}: Student '#{new_student.id}' does not have the 'school-student' role for organisation '#{school.id}'")
        end

        it 'sent the exception to Sentry' do
          described_class.call(school_class:, students:)
          expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
        end
      end

      context 'when one creation fails' do
        let(:new_students) { students + [new_student] }
        let(:student_ids) { students.map(&:id) << failed_student_id }

        it 'returns a successful operation response' do
          response = described_class.call(school_class:, students: new_students)
          expect(response.success?).to be(true)
        end

        it 'returns a class members JSON array' do
          response = described_class.call(school_class:, students: new_students)
          expect(response[:class_members].size).to eq(3)
        end

        it 'returns class members in the operation response' do
          response = described_class.call(school_class:, students: new_students)
          expect(response[:class_members]).to all(be_a(ClassMember))
        end

        it 'assigns the school_class' do
          response = described_class.call(school_class:, students: new_students)
          expect(response[:class_members]).to all(have_attributes(school_class:))
        end

        it 'assigns the successful students' do
          response = described_class.call(school_class:, students: new_students)
          expected_student_ids = student_ids - [failed_student_id]
          expect(response[:class_members].map(&:student_id)).to match_array(expected_student_ids)
        end

        it 'returns the error messages in the operation response' do
          response = described_class.call(school_class:, students: new_students)
          expect(response[:errors][failed_student_id]).to eq("Error creating class member for student_id #{new_student.id}: Student '#{new_student.id}' does not have the 'school-student' role for organisation '#{school.id}'")
        end

        it 'sent the exception to Sentry' do
          described_class.call(school_class:, students: new_students)
          expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
        end
      end
    end
  end
end
