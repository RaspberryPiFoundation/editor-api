# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClassMember::Create, type: :unit do
  before do
    stub_user_info_api_for_teacher(teacher_id:, school_id: School::ID)
    stub_user_info_api_for_student(student_id:, school_id: School::ID)
  end

  let!(:school_class) { create(:school_class, teacher_id:, school:) }
  let(:school) { build(:school, id: School::ID) }
  let(:student_id) { SecureRandom.uuid }
  let(:teacher_id) { SecureRandom.uuid }

  let(:class_member_params) do
    { student_id: }
  end

  it 'returns a successful operation response' do
    response = described_class.call(school_class:, class_member_params:)
    expect(response.success?).to be(true)
  end

  it 'creates a school class' do
    expect { described_class.call(school_class:, class_member_params:) }.to change(ClassMember, :count).by(1)
  end

  it 'returns the class member in the operation response' do
    response = described_class.call(school_class:, class_member_params:)
    expect(response[:class_member]).to be_a(ClassMember)
  end

  it 'assigns the school_class' do
    response = described_class.call(school_class:, class_member_params:)
    expect(response[:class_member].school_class).to eq(school_class)
  end

  it 'assigns the student_id' do
    response = described_class.call(school_class:, class_member_params:)
    expect(response[:class_member].student_id).to eq(student_id)
  end

  context 'when creation fails' do
    let(:class_member_params) { {} }

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'does not create a class member' do
      expect { described_class.call(school_class:, class_member_params:) }.not_to change(ClassMember, :count)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school_class:, class_member_params:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school_class:, class_member_params:)
      expect(response[:error]).to match(/Error creating class member/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school_class:, class_member_params:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
