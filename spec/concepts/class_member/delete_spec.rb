# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClassMember::Delete, type: :unit do
  before do
    stub_user_info_api_for_teacher
    stub_user_info_api_for_student(student_id: User::STUDENT_ID)
  end

  let!(:class_member) { create(:class_member) }
  let(:class_member_id) { class_member.id }
  let(:school_class) { class_member.school_class }
  let(:school) { school_class.school }

  it 'returns a successful operation response' do
    response = described_class.call(school_class:, class_member_id:)
    expect(response.success?).to be(true)
  end

  it 'deletes a class member' do
    expect { described_class.call(school_class:, class_member_id:) }.to change(ClassMember, :count).by(-1)
  end

  context 'when deletion fails' do
    let(:class_member_id) { 'does-not-exist' }

    before do
      allow(Sentry).to receive(:capture_exception)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school_class:, class_member_id:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school_class:, class_member_id:)
      expect(response[:error]).to match(/does-not-exist/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school_class:, class_member_id:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
