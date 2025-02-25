# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolClass::Create, type: :unit do
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:) }

  let(:school_class_params) do
    { name: 'Test School Class' }
  end

  it 'returns a successful operation response' do
    response = described_class.call(school:, school_class_params:, current_user: teacher)
    expect(response.success?).to be(true)
  end

  it 'creates a school class' do
    expect { described_class.call(school:, school_class_params:, current_user: teacher) }.to change(SchoolClass, :count).by(1)
  end

  it 'returns the school class in the operation response' do
    response = described_class.call(school:, school_class_params:, current_user: teacher)
    expect(response[:school_class]).to be_a(SchoolClass)
  end

  it 'assigns the school' do
    response = described_class.call(school:, school_class_params:, current_user: teacher)
    expect(response[:school_class].school).to eq(school)
  end

  it 'assigns the name' do
    response = described_class.call(school:, school_class_params:, current_user: teacher)
    expect(response[:school_class].name).to eq('Test School Class')
  end

  it 'assigns the teacher' do
    response = described_class.call(school:, school_class_params:, current_user: teacher)
    expect(response[:school_class].teacher_ids).to eq([teacher.id])
  end

  context 'when creation fails' do
    let(:school_class_params) { {} }

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'does not create a school class' do
      expect { described_class.call(school:, school_class_params:, current_user: teacher) }.not_to change(SchoolClass, :count)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school:, school_class_params:, current_user: teacher)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, school_class_params:, current_user: teacher)
      expect(response[:error]).to match(/Error creating school class/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school:, school_class_params:, current_user: teacher)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
