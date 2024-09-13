# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolTeacher::List, type: :unit do
  let(:school) { create(:school) }
  let(:teachers) { create_list(:teacher, 3, school:) }
  let(:teacher_ids) { teachers.map(&:id) }

  context 'when successful' do
    context 'when not passing teacher_ids' do
      let(:response) { described_class.call(school:) }

      before do
        stub_user_info_api_for_users(teacher_ids, users: teachers)
      end

      # rubocop:disable RSpec/MultipleExpectations
      it 'returns a successful response with school teachers' do
        expect(response[:school_teachers]).to eq(teachers)
        expect(response[:error]).to be_nil
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context 'when passing teacher_ids' do
      let(:response) { described_class.call(school:, teacher_ids:) }

      before do
        stub_user_info_api_for(teachers[1])
      end

      # rubocop:disable RSpec/MultipleExpectations
      it 'returns a successful response with school teachers' do
        expect(response[:school_teachers].first.id).to eq(teachers[1].id)
        expect(response[:error]).to be_nil
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end

  context 'when an error occurs' do
    let(:response) { described_class.call(school:, teacher_ids:) }

    let(:error_message) { 'Error listing school teachers: some error' }

    before do
      allow(User).to receive(:from_userinfo).with(ids: teacher_ids).and_raise(StandardError.new('some error'))
      allow(Sentry).to receive(:capture_exception)
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'captures the exception and returns an error response' do
      # Call the method to ensure the error is raised and captured
      response
      expect(Sentry).to have_received(:capture_exception).with(instance_of(StandardError))
      expect(response[:school_teachers]).to be_nil
      expect(response[:error]).to eq(error_message)
    end
    # rubocop:enable RSpec/MultipleExpectations
  end
end
