# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImportSchoolsJob do
  describe '#perform' do
    let(:token) { 'test-token' }
    let(:user_id) { SecureRandom.uuid }
    let(:owner1_id) { SecureRandom.uuid }
    let(:owner2_id) { SecureRandom.uuid }

    let(:schools_data) do
      [
        {
          name: 'Test School 1',
          website: 'https://test1.example.com',
          address_line_1: '123 Main St',
          municipality: 'Springfield',
          country_code: 'US',
          owner_email: 'owner1@example.com'
        },
        {
          name: 'Test School 2',
          website: 'https://test2.example.com',
          address_line_1: '456 Oak Ave',
          municipality: 'Boston',
          country_code: 'US',
          owner_email: 'owner2@example.com'
        }
      ]
    end

    before do
      allow(UserInfoApiClient).to receive(:search_by_email)
        .with('owner1@example.com')
        .and_return([{ id: owner1_id, email: 'owner1@example.com' }])

      allow(UserInfoApiClient).to receive(:search_by_email)
        .with('owner2@example.com')
        .and_return([{ id: owner2_id, email: 'owner2@example.com' }])
    end

    context 'when all schools can be created successfully' do
      it 'creates schools and returns successful results' do
        results = described_class.new.perform(
          schools_data: schools_data,
          user_id: user_id,
          token: token
        )

        expect(results[:successful].count).to eq(2)
        expect(results[:failed].count).to eq(0)

        school_1 = School.find_by(name: 'Test School 1')
        expect(school_1).to be_present
        expect(school_1.verified?).to be true
        expect(school_1.code).to be_present
        expect(school_1.user_origin).to eq('experience_cs')

        # Check owner role was created
        expect(Role.owner.exists?(school_id: school_1.id, user_id: owner1_id)).to be true
      end
    end

    context 'when owner email is not found' do
      before do
        allow(UserInfoApiClient).to receive(:search_by_email)
          .with('owner1@example.com')
          .and_return([])
      end

      it 'adds failed result for that school' do
        results = described_class.new.perform(
          schools_data: [schools_data.first],
          user_id: user_id,
          token: token
        )

        expect(results[:successful].count).to eq(0)
        expect(results[:failed].count).to eq(1)
        expect(results[:failed].first[:error_code]).to eq('OWNER_NOT_FOUND')
        expect(results[:failed].first[:error]).to include('Owner not found')
      end
    end

    context 'when owner already created another school' do
      before do
        school = create(:school, creator_id: owner1_id)
        school.verify!

        allow(UserInfoApiClient).to receive(:search_by_email)
          .with('owner1@example.com')
          .and_return([{ id: owner1_id, email: 'owner1@example.com' }])
      end

      it 'adds failed result for that school' do
        results = described_class.new.perform(
          schools_data: [schools_data.first],
          user_id: user_id,
          token: token
        )

        expect(results[:successful].count).to eq(0)
        expect(results[:failed].count).to eq(1)
        expect(results[:failed].first[:error_code]).to eq('OWNER_ALREADY_CREATOR')
        expect(results[:failed].first[:error]).to include('already the creator')
      end
    end

    context 'when school validation fails' do
      let(:invalid_schools_data) do
        [{
          name: '',
          website: 'https://test.example.com',
          address_line_1: '123 Main St',
          municipality: 'Springfield',
          country_code: 'US',
          owner_email: 'owner1@example.com'
        }]
      end

      before do
        allow(UserInfoApiClient).to receive(:search_by_email)
          .with('owner1@example.com')
          .and_return([{ id: owner1_id, email: 'owner1@example.com' }])
      end

      it 'adds failed result with validation errors' do
        results = described_class.new.perform(
          schools_data: invalid_schools_data,
          user_id: user_id,
          token: token
        )

        expect(results[:successful].count).to eq(0)
        expect(results[:failed].count).to eq(1)
        expect(results[:failed].first[:error_code]).to eq('SCHOOL_VALIDATION_FAILED')
        expect(results[:failed].first[:error]).to be_present
      end
    end

    context 'when some schools succeed and some fail' do
      before do
        allow(UserInfoApiClient).to receive(:search_by_email)
          .with('owner1@example.com')
          .and_return([{ id: owner1_id, email: 'owner1@example.com' }])

        allow(UserInfoApiClient).to receive(:search_by_email)
          .with('owner2@example.com')
          .and_return([])
      end

      it 'returns partial success results' do
        results = described_class.new.perform(
          schools_data: schools_data,
          user_id: user_id,
          token: token
        )

        expect(results[:successful].count).to eq(1)
        expect(results[:failed].count).to eq(1)
        expect(results[:successful].first[:name]).to eq('Test School 1')
        expect(results[:failed].first[:name]).to eq('Test School 2')
      end
    end
  end
end
