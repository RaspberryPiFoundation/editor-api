# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolClass::Delete, type: :unit do
  before do
    create(:class_student, student_id: student.id, school_class:)
  end

  let(:school_class) { build(:school_class, teacher_ids: [teacher.id], school:) }
  let(:school_class_id) { school_class.id }
  let(:school) { create(:school) }
  let(:student) { create(:student, school:) }
  let(:teacher) { create(:teacher, school:) }

  it 'returns a successful operation response' do
    response = described_class.call(school:, school_class_id:)
    expect(response.success?).to be(true)
  end

  it 'deletes a school class' do
    expect { described_class.call(school:, school_class_id:) }.to change(SchoolClass, :count).by(-1)
  end

  it 'deletes class students in the school class' do
    expect { described_class.call(school:, school_class_id:) }.to change(ClassStudent, :count).by(-1)
  end

  it 'deletes class teachers in the school class' do
    expect { described_class.call(school:, school_class_id:) }.to change(ClassTeacher, :count).by(-1)
  end

  context 'when deletion fails' do
    let(:school_class_id) { 'does-not-exist' }

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school:, school_class_id:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, school_class_id:)
      expect(response[:error]).to match(/does-not-exist/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school:, school_class_id:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
