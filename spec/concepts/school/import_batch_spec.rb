# frozen_string_literal: true

require 'rails_helper'

RSpec.describe School::ImportBatch do
  describe '.call' do
    let(:current_user) { instance_double(User, id: SecureRandom.uuid, token: 'test-token') }
    let(:csv_content) do
      <<~CSV
        name,website,address_line_1,municipality,country_code,owner_email
        Test School 1,https://test1.example.com,123 Main St,Springfield,US,owner1@example.com
        Test School 2,https://test2.example.com,456 Oak Ave,Boston,US,owner2@example.com
      CSV
    end
    let(:csv_file) { StringIO.new(csv_content) }

    before do
      allow(SchoolImportJob).to receive(:perform_later).and_return(
        instance_double(SchoolImportJob, job_id: 'test-job-id')
      )
    end

    context 'with valid CSV' do
      it 'returns success response with job_id' do
        result = described_class.call(csv_file: csv_file, current_user: current_user)

        expect(result.success?).to be true
        expect(result[:job_id]).to eq('test-job-id')
        expect(result[:total_schools]).to eq(2)
      end

      it 'enqueues SchoolImportJob' do
        described_class.call(csv_file: csv_file, current_user: current_user)

        expect(SchoolImportJob).to have_received(:perform_later).with(
          hash_including(
            schools_data: array_including(
              hash_including(name: 'Test School 1'),
              hash_including(name: 'Test School 2')
            ),
            user_id: current_user.id,
            token: current_user.token
          )
        )
      end
    end

    context 'with missing required headers' do
      let(:csv_content) do
        <<~CSV
          name,website
          Test School,https://test.example.com
        CSV
      end

      it 'returns error response' do
        result = described_class.call(csv_file: csv_file, current_user: current_user)

        expect(result.failure?).to be true
        expect(result[:error][:error_code]).to eq('CSV_INVALID_FORMAT')
        expect(result[:error][:message]).to include('Invalid CSV format')
      end
    end

    context 'with invalid country code' do
      let(:csv_content) do
        <<~CSV
          name,website,address_line_1,municipality,country_code,owner_email
          Test School,https://test.example.com,123 Main St,Springfield,INVALID,owner@example.com
        CSV
      end

      it 'returns validation error' do
        result = described_class.call(csv_file: csv_file, current_user: current_user)

        expect(result.failure?).to be true
        expect(result[:error][:error_code]).to eq('CSV_VALIDATION_FAILED')
        expect(result[:error][:details][:row_errors]).to be_present
      end
    end

    context 'with malformed CSV' do
      let(:csv_file) { StringIO.new('this is not csv,,"') }

      it 'returns error response' do
        result = described_class.call(csv_file: csv_file, current_user: current_user)

        expect(result.failure?).to be true
        expect(result[:error][:error_code]).to eq('CSV_MALFORMED')
      end
    end
  end
end
