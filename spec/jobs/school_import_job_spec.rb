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
          administrative_area: 'Massachusetts',
          municipality: 'Springfield',
          postal_code: '01101',
          country_code: 'US',
          owner_email: 'owner1@example.com',
          district_name: 'Some District',
          district_nces_id: '0100000'
        },
        {
          name: 'Test School 2',
          website: 'https://test2.example.com',
          address_line_1: '456 Oak Ave',
          administrative_area: 'Massachusetts',
          municipality: 'Boston',
          postal_code: '02101',
          country_code: 'US',
          owner_email: 'owner2@example.com',
          district_name: 'Other District',
          district_nces_id: '0100001'
        }
      ]
    end

    before do
      allow(ProfileApiClient).to receive(:create_school).and_return(true)
    end

    context 'when all schools can be created successfully' do
      before do
        stub_user_info_api_find_by_email(
          email: 'owner1@example.com',
          user: { id: owner1_id, email: 'owner1@example.com' }
        )

        stub_user_info_api_find_by_email(
          email: 'owner2@example.com',
          user: { id: owner2_id, email: 'owner2@example.com' }
        )
      end

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

        # Check owner and teacher roles were created
        expect(Role.owner.exists?(school_id: school_1.id, user_id: owner1_id)).to be true
        expect(Role.teacher.exists?(school_id: school_1.id, user_id: owner1_id)).to be true
      end
    end

    context 'when owner email is not found' do
      before do
        stub_user_info_api_find_by_email(email: 'owner1@example.com', user: nil)
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

    context 'when owner already has a role in another school' do
      let(:existing_school) { create(:school, name: 'Existing School') }

      before do
        Role.owner.create!(school_id: existing_school.id, user_id: owner1_id)

        stub_user_info_api_find_by_email(
          email: 'owner1@example.com',
          user: { id: owner1_id, email: 'owner1@example.com' }
        )
      end

      it 'adds failed result for that school' do
        results = described_class.new.perform(
          schools_data: [schools_data.first],
          user_id: user_id,
          token: token
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
            'administrative_area' => 'Massachusetts',
            'municipality' => 'Springfield',
            'postal_code' => '01101',
            'country_code' => 'us',
            'owner_email' => 'owner1@example.com',
            'district_name' => 'Some District',
            'district_nces_id' => '0100000'
          }
        ]
      end

      before do
        stub_user_info_api_find_by_email(
          email: 'owner1@example.com',
          user: { id: owner1_id, email: 'owner1@example.com' }
        )
      end

      it 'handles string keys correctly' do
        results = described_class.new.perform(
          schools_data: schools_data_with_string_keys,
          user_id: user_id,
          token: token
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
