# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolStudent::List, type: :unit do
  let(:token) { UserProfileMock::TOKEN }
  let(:school) { create(:school) }
  let(:students) { create_list(:student, 3, school:) }

  context 'without student_ids' do
    before do
      student_attributes = students.map do |student|
        { id: student.id, name: student.name, username: student.username }
      end
      stub_profile_api_list_school_students(school:, student_attributes:)
    end

    it 'returns a successful operation response' do
      response = described_class.call(school:, token:)
      expect(response.success?).to be(true)
    end

    it 'makes a profile API call' do
      described_class.call(school:, token:)

      # TODO: Replace with WebMock assertion once the profile API has been built.
      expect(ProfileApiClient).to have_received(:list_school_students).with(token:, school_id: school.id, student_ids: students.map(&:id))
    end

    it 'returns a school students JSON array' do
      response = described_class.call(school:, token:)
      expect(response[:school_students].size).to eq(3)
    end

    it 'returns the school students in the operation response' do
      response = described_class.call(school:, token:)
      students.each do |student|
        expected_user = User.new(id: student.id, name: student.name, username: student.username)
        expect(response[:school_students]).to include(expected_user)
      end
    end
  end

  context 'with student_ids' do
    let(:student_ids) { students.map(&:id).take(2) }
    let(:filtered_students) { students.select { |student| student_ids.include?(student.id) } }

    before do
      student_attributes = filtered_students.map do |student|
        { id: student.id, name: student.name, username: student.username }
      end
      stub_profile_api_list_school_students(school:, student_attributes:)
    end

    it 'returns a successful operation response' do
      response = described_class.call(school:, token:, student_ids:)
      expect(response.success?).to be(true)
    end

    it 'makes a profile API call' do
      described_class.call(school:, token:, student_ids:)

      # TODO: Replace with WebMock assertion once the profile API has been built.
      expect(ProfileApiClient).to have_received(:list_school_students).with(token:, school_id: school.id, student_ids:)
    end

    it 'returns a filtered school students JSON array' do
      response = described_class.call(school:, token:, student_ids:)
      expect(response[:school_students].size).to eq(2)
    end

    it 'returns the filtered school students in the operation response' do
      response = described_class.call(school:, token:, student_ids:)
      filtered_students.each do |student|
        expected_user = User.new(id: student.id, name: student.name, username: student.username)
        expect(response[:school_students]).to include(expected_user)
      end
    end
  end

  context 'when listing fails' do
    let(:student_ids) { [123] }

    before do
      allow(ProfileApiClient).to receive(:list_school_students).and_raise('Some API error')
      allow(Sentry).to receive(:capture_exception)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school:, token:, student_ids:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, token:, student_ids:)
      expect(response[:error]).to match(/Some API error/)
    end

    it 'sent the exception to Sentry' do
      described_class.call(school:, token:, student_ids:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end
  end
end
