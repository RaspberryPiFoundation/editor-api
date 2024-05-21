# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolClass::Update, type: :unit do
  let(:school_class) { create(:school_class, name: 'Test School Class Name', teacher_id: User::TEACHER_ID, school: build(:school, id: School::ID)) }
  let(:school_class_params) { { name: 'New Name' } }

  before do
    stub_user_info_api_for_teacher(teacher_id: User::TEACHER_ID, school_id: School::ID)
  end

  it 'returns a successful operation response' do
    response = described_class.call(school_class:, school_class_params:)
    expect(response.success?).to be(true)
  end

  it 'updates the school class' do
    response = described_class.call(school_class:, school_class_params:)
    expect(response[:school_class].name).to eq('New Name')
  end

  it 'returns the school class in the operation response' do
    response = described_class.call(school_class:, school_class_params:)
    expect(response[:school_class]).to be_a(SchoolClass)
  end

  context 'when updating fails' do
    let(:school_class_params) { { name: ' ' } }

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'does not update the school class' do
      response = described_class.call(school_class:, school_class_params:)
      expect(response[:school_class].reload.name).to eq('Test School Class Name')
    end

    it 'returns a failed operation response' do
      response = described_class.call(school_class:, school_class_params:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school_class:, school_class_params:)
      expect(response[:error]).to match(/Error updating school/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school_class:, school_class_params:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
