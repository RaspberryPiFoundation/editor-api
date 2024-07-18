# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClassMember::Create, type: :unit do
  let!(:school_class) { create(:school_class, teacher_id: teacher.id, school:) }
  let(:school) { create(:school) }
  let(:students) { create_list(:student, 3, school:) }
  let(:teacher) { create(:teacher, school:) }

  let(:failed_student_id) { 'i-am-not-an-id' }
  let(:student_ids) { students.map(&:id) }

  it 'returns a successful operation response' do
    response = described_class.call(school_class:, student_ids:)
    expect(response.success?).to be(true)
  end

  it 'creates a school class' do
    expect { described_class.call(school_class:, student_ids:) }.to change(ClassMember, :count).by(3)
  end

  it 'returns a class members JSON array' do
    response = described_class.call(school_class:, student_ids:)
    expect(response[:class_members].size).to eq(3)
  end

  it 'returns class members in the operation response' do
    response = described_class.call(school_class:, student_ids:)
    expect(response[:class_members]).to all(be_a(ClassMember))
  end

  it 'assigns the school_class' do
    response = described_class.call(school_class:, student_ids:)
    expect(response[:class_members]).to all(have_attributes(school_class: school_class))
  end

  it 'assigns the student_id' do
    response = described_class.call(school_class:, student_ids:)
    expect(response[:class_members].map(&:student_id)).to match_array(student_ids)
  end

  context 'with an empty array of student_ids' do
    it 'returns a successful operation response' do
      response = described_class.call(school_class:, student_ids: [])
      expect(response[:class_members]).to eq([])
    end
  end

  context 'when creations fail' do
    before do
      allow(Sentry).to receive(:capture_exception)
    end

    context 'with malformed student_ids' do
      let(:student_ids) { nil }
      
      it 'does not create a class member' do
        expect { described_class.call(school_class:, student_ids:) }.not_to change(ClassMember, :count)
      end

      it 'returns a failed operation response' do
        response = described_class.call(school_class:, student_ids:)
        expect(response.failure?).to be(true)
      end

      it 'returns the error message in the operation response' do
        response = described_class.call(school_class:, student_ids:)
        expect(response[:error]).to match(/Error creating class members/)
      end

      it 'sent the exception to Sentry' do
        described_class.call(school_class:, student_ids:)
        expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
      end
    end

    context 'with non existent student_ids' do
      let(:student_ids) { [failed_student_id] }
      
      it 'does not create a class member' do
        expect { described_class.call(school_class:, student_ids:) }.not_to change(ClassMember, :count)
      end

      it 'returns a successful operation response' do
        response = described_class.call(school_class:, student_ids:)
        expect(response.success?).to be(true)
      end

      it 'returns a successful operation response' do
        response = described_class.call(school_class:, student_ids:)
        expect(response[:class_members]).to eq([])
      end

      it 'returns the error messages in the operation response' do
        response = described_class.call(school_class:, student_ids:)
        expect(response[:errors][failed_student_id]).to include("Error creating class member for student_id #{student_ids.first}: Student can't be blank")
      end

      it 'sent the exception to Sentry' do
        described_class.call(school_class:, student_ids:)
        expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
      end
    end

    context 'when one creation fails' do
      let(:student_ids) { students.map(&:id) << failed_student_id }

      it 'returns a successful operation response' do
        response = described_class.call(school_class:, student_ids:)
        expect(response.success?).to be(true)
      end

      it 'returns a class members JSON array' do
        response = described_class.call(school_class:, student_ids:)
        expect(response[:class_members].size).to eq(3)
      end

      it 'returns class members in the operation response' do
        response = described_class.call(school_class:, student_ids:)
        expect(response[:class_members]).to all(be_a(ClassMember))
      end

      it 'assigns the school_class' do
        response = described_class.call(school_class:, student_ids:)
        expect(response[:class_members]).to all(have_attributes(school_class: school_class))
      end

      it 'assigns the successful student_ids' do
        response = described_class.call(school_class:, student_ids:)
        expected_student_ids = student_ids - [failed_student_id]
        expect(response[:class_members].map(&:student_id)).to match_array(expected_student_ids)
      end

      it 'returns the error messages in the operation response' do
        response = described_class.call(school_class:, student_ids:)
        expect(response[:errors][failed_student_id]).to eq("Error creating class member for student_id #{student_ids.last}: Student can't be blank")
      end

      it 'sent the exception to Sentry' do
        described_class.call(school_class:, student_ids:)
        expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
      end
    end
  end
end
