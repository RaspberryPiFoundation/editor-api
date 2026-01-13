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

  it 'marks the school class as deleted' do
    described_class.call(school:, school_class_id:)
    expect(school_class.reload.deleted?).to be true
  end

  it 'does not delete the school class record' do
    expect { described_class.call(school:, school_class_id:) }.not_to change(SchoolClass, :count)
  end

  it 'does not delete class students in the school class' do
    expect { described_class.call(school:, school_class_id:) }.not_to change(ClassStudent, :count)
  end

  it 'does not delete class teachers in the school class' do
    expect { described_class.call(school:, school_class_id:) }.not_to change(ClassTeacher, :count)
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
