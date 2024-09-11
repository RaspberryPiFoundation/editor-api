# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolTeacher::List, type: :unit do
  let(:school) { create(:school) }
  let(:teachers) { create_list(:teacher, 3, school: school) }
  let(:teacher_ids) { teachers.map(&:id) }
  let(:response) { described_class.call(teacher_ids: teacher_ids) }

  context 'when successful' do
    before do
      allow(User).to receive(:from_userinfo).with(ids: teacher_ids).and_return(teachers)
    end

    it 'returns a successful response with school teachers' do
      expect(response[:school_teachers]).to eq(teachers)
      expect(response[:error]).to be_nil
    end
  end

  context 'when an error occurs' do
    let(:error_message) { 'Error listing school teachers: some error' }

    before do
      allow(User).to receive(:from_userinfo).with(ids: teacher_ids).and_raise(StandardError.new('some error'))
      allow(Sentry).to receive(:capture_exception)
    end

    it 'captures the exception and returns an error response' do
      # Call the method to ensure the error is raised and captured
      response
      expect(Sentry).to have_received(:capture_exception).with(instance_of(StandardError))
      expect(response[:school_teachers]).to be_nil
      expect(response[:error]).to eq(error_message)
    end
  end
end
