# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolImportJob do
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
      allow(UserInfoApiClient).to receive(:find_user_by_email)
        .with('owner1@example.com')
        .and_return({ id: owner1_id, email: 'owner1@example.com' })

      allow(UserInfoApiClient).to receive(:find_user_by_email)
        .with('owner2@example.com')
        .and_return({ id: owner2_id, email: 'owner2@example.com' })
    end

    context 'when all schools can be created successfully' do
      it 'creates schools and returns successful results' do
        results = described_class.new.perform(
          schools_data: schools_data,
          user_id: user_id
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
        allow(UserInfoApiClient).to receive(:find_user_by_email)
          .with('owner1@example.com')
          .and_return(nil)
      end

      it 'adds failed result for that school' do
        results = described_class.new.perform(
          schools_data: [schools_data.first],
          user_id: user_id
        )

        expect(results[:successful].count).to eq(0)
        expect(results[:failed].count).to eq(1)
        expect(results[:failed].first[:error_code]).to eq('OWNER_NOT_FOUND')
        expect(results[:failed].first[:error]).to include('Owner not found')
      end
    end

    context 'when owner already has a role in another school' do
      let(:existing_school) { create(:school, name: 'Existing School') }

      before do
        Role.owner.create!(school_id: existing_school.id, user_id: owner1_id)
      end

      it 'adds failed result for that school' do
        results = described_class.new.perform(
          schools_data: [schools_data.first],
          user_id: user_id
        )

        expect(results[:successful].count).to eq(0)
        expect(results[:failed].count).to eq(1)
        expect(results[:failed].first[:error_code]).to eq('OWNER_HAS_EXISTING_ROLE')
        expect(results[:failed].first[:error]).to include('already has a role in school')
        expect(results[:failed].first[:existing_school_id]).to eq(existing_school.id)
      end
    end

    context 'when schools_data has string keys (simulating ActiveJob serialization)' do
      let(:schools_data_with_string_keys) do
        [
          {
            'name' => 'Test School 1',
            'website' => 'https://test1.example.com',
            'address_line_1' => '123 Main St',
            'municipality' => 'Springfield',
            'country_code' => 'us',
            'owner_email' => 'owner1@example.com'
          }
        ]
      end

      before do
        allow(UserInfoApiClient).to receive(:find_user_by_email)
          .with('owner1@example.com')
          .and_return({ id: owner1_id, email: 'owner1@example.com' })
      end

      it 'handles string keys correctly' do
        results = described_class.new.perform(
          schools_data: schools_data_with_string_keys,
          user_id: user_id
        )

        expect(results[:successful].count).to eq(1)
        expect(results[:failed].count).to eq(0)

        school = School.find_by(name: 'Test School 1')
        expect(school).to be_present
        expect(school.country_code).to eq('US')
      end
    end
  end
end
