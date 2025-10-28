# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClassMember::Create, type: :unit do
  let!(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
  let(:school) { create(:school) }
  let(:students) { create_list(:student, 3, school:) }
  let(:teacher) { create(:teacher, school:) }
  let(:teachers) { Array.new(2) { create(:teacher, school:) } }

  let(:student_ids) { students.map(&:id) }

  it 'returns a successful operation response' do
    response = described_class.call(school_class:, students:, teachers:)
    expect(response.success?).to be(true)
  end

  it 'creates class students' do
    expect { described_class.call(school_class:, students:, teachers:) }.to change(ClassStudent, :count).by(3)
  end

  it 'creates class teachers' do
    expect { described_class.call(school_class:, students:, teachers:) }.to change(ClassTeacher, :count).by(2)
  end

  it 'returns a class members JSON array' do
    response = described_class.call(school_class:, students:, teachers:)
    expect(response[:class_members].size).to eq(5)
  end

  it 'returns class students in the operation response' do
    response = described_class.call(school_class:, students:, teachers:)
    class_students_count = response[:class_members].count { |member| member.is_a?(ClassStudent) }
    expect(class_students_count).to eq(3)
  end

  it 'returns class teachers in the operation response' do
    response = described_class.call(school_class:, students:, teachers:)
    class_teachers_count = response[:class_members].count { |member| member.is_a?(ClassTeacher) }
    expect(class_teachers_count).to eq(2)
  end

  it 'assigns the school_class' do
    response = described_class.call(school_class:, students:)
    expect(response[:class_members]).to all(have_attributes(school_class:))
  end

  it 'assigns the student_id' do
    response = described_class.call(school_class:, students:, teachers:)
    response_students = response[:class_members].select { |member| member.is_a?(ClassStudent) }
    expect(response_students.map(&:student_id)).to match_array(student_ids)
  end

  it 'assigns the teacher_id' do
    teacher_ids = teachers.map(&:id)
    response = described_class.call(school_class:, students:, teachers:)
    response_teachers = response[:class_members].select { |member| member.is_a?(ClassTeacher) }
    expect(response_teachers.map(&:teacher_id)).to match_array(teacher_ids)
  end

  context 'when creations fail' do
    before do
      allow(Sentry).to receive(:capture_exception)
    end

    context 'with malformed members' do
      let(:students) { nil }
      let(:teachers) { nil }

      it 'does not create a class student' do
        expect { described_class.call(school_class:, students:, teachers:) }.not_to change(ClassStudent, :count)
      end

      it 'does not create a class teacher' do
        expect { described_class.call(school_class:, students:, teachers:) }.not_to change(ClassTeacher, :count)
      end

      it 'returns a failed operation response' do
        response = described_class.call(school_class:, students:, teachers:)
        expect(response.failure?).to be(true)
      end

      it 'returns the error message in the operation response' do
        response = described_class.call(school_class:, students:, teachers:)
        expect(response[:error]).to match(/No valid school members provided/)
      end

      it 'sent the exception to Sentry' do
        described_class.call(school_class:, students:, teachers:)
        expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
      end
    end

    context 'with a student from a different school' do
      let(:different_school_student) { create(:student, school: create(:school)) }

      context 'with non existent students' do
        let(:students) { [different_school_student] }

        it 'does not create a class member' do
          expect { described_class.call(school_class:, students:) }.not_to change(ClassStudent, :count)
        end

        it 'returns an unsuccessful operation response' do
          response = described_class.call(school_class:, students:)
          expect(response.success?).to be(false)
        end

        it 'returns an empty class members array' do
          response = described_class.call(school_class:, students:)
          expect(response[:class_members]).to eq([])
        end

        it 'returns a generic error message in the operation response referencing the errors Hash' do
          response = described_class.call(school_class:, students:)
          expect(response[:error]).to include("Error creating one or more class members - see 'errors' key for details")
        end

        it 'returns the error messages in the operation response' do
          response = described_class.call(school_class:, students:)
          expect(response[:errors][different_school_student.id]).to include("Error creating class member for student_id #{different_school_student.id}: Student '#{different_school_student.id}' does not have the 'school-student' role for organisation '#{school.id}'")
        end

        it 'sent the exception to Sentry' do
          described_class.call(school_class:, students:)
          expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
        end
      end

      context 'when one creation fails' do
        let(:new_students) { students + [different_school_student] }

        it 'returns an unsuccessful operation response' do
          response = described_class.call(school_class:, students: new_students, teachers:)
          expect(response.success?).to be(false)
        end

        it 'returns a class members JSON array' do
          response = described_class.call(school_class:, students: new_students, teachers:)
          expect(response[:class_members].size).to eq(5)
        end

        it 'returns class students in the operation response' do
          response = described_class.call(school_class:, students: new_students, teachers:)
          class_students_count = response[:class_members].count { |member| member.is_a?(ClassStudent) }
          expect(class_students_count).to eq(3)
        end

        it 'returns class teachers in the operation response' do
          response = described_class.call(school_class:, students: new_students, teachers:)
          class_teachers_count = response[:class_members].count { |member| member.is_a?(ClassTeacher) }
          expect(class_teachers_count).to eq(2)
        end

        it 'assigns the school_class' do
          response = described_class.call(school_class:, students: new_students, teachers:)
          expect(response[:class_members]).to all(have_attributes(school_class:))
        end

        it 'assigns the successful students' do
          response = described_class.call(school_class:, students: new_students, teachers:)
          response_students = response[:class_members].select { |member| member.is_a?(ClassStudent) }
          expect(response_students.map(&:student_id)).to match_array(student_ids)
        end

        it 'assigns the successful teachers' do
          teacher_ids = teachers.map(&:id)
          response = described_class.call(school_class:, students: new_students, teachers:)
          response_teachers = response[:class_members].select { |member| member.is_a?(ClassTeacher) }
          expect(response_teachers.map(&:teacher_id)).to match_array(teacher_ids)
        end

        it 'returns a generic error message in the operation response referencing the errors Hash' do
          response = described_class.call(school_class:, students: new_students, teachers:)
          expect(response[:error]).to include("Error creating one or more class members - see 'errors' key for details")
        end

        it 'returns the error messages in the operation response' do
          response = described_class.call(school_class:, students: new_students, teachers:)
          expect(response[:errors][different_school_student.id]).to eq("Error creating class member for student_id #{different_school_student.id}: Student '#{different_school_student.id}' does not have the 'school-student' role for organisation '#{school.id}'")
        end

        it 'sent the exception to Sentry' do
          described_class.call(school_class:, students: new_students, teachers:)
          expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
        end
      end
    end

    context 'when duplicate validation errors occur' do
      it 'does not send the exception to Sentry' do
        duplicate_student = students.first
        described_class.call(school_class:, students: [duplicate_student, duplicate_student])
        expect(Sentry).not_to have_received(:capture_exception)
      end
    end
  end
end
