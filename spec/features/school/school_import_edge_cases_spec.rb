# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'School Import - Edge Cases and Concurrency', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:admin_user) { create(:user, roles: 'experience-cs-admin') }

  before do
    authenticated_in_hydra_as(admin_user)
  end

  describe 'Edge Cases' do
    context 'when CSV is empty (only headers)' do
      let(:csv_content) do
        <<~CSV
          name,website,address_line_1,municipality,country_code,owner_email
        CSV
      end

      let(:csv_file) do
        tempfile = Tempfile.new(['schools_empty', '.csv'])
        tempfile.write(csv_content)
        tempfile.rewind
        Rack::Test::UploadedFile.new(tempfile.path, 'text/csv')
      end

      it 'accepts empty CSV and returns 0 schools' do
        allow(ImportSchoolsJob).to receive(:perform_later).and_return(instance_double(ImportSchoolsJob, job_id: 'test-job-id'))

        post('/api/schools/import', headers: headers, params: { csv_file: csv_file })

        expect(response).to have_http_status(:accepted)
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:total_schools]).to eq(0)
      end
    end

    context 'when CSV has duplicate owner emails' do
      let(:csv_content) do
        <<~CSV
          name,website,address_line_1,municipality,country_code,owner_email
          Test School 1,https://test1.example.com,123 Main St,Springfield,US,owner@example.com
          Test School 2,https://test2.example.com,456 Oak Ave,Boston,US,owner@example.com
        CSV
      end

      let(:csv_file) do
        tempfile = Tempfile.new(['schools_duplicate', '.csv'])
        tempfile.write(csv_content)
        tempfile.rewind
        Rack::Test::UploadedFile.new(tempfile.path, 'text/csv')
      end

      it 'rejects CSV with duplicate owner emails' do
        post('/api/schools/import', headers: headers, params: { csv_file: csv_file })

        expect(response).to have_http_status(:unprocessable_entity)
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:error_code]).to eq('DUPLICATE_OWNER_EMAIL')
        expect(data[:details][:duplicate_emails]).to include('owner@example.com')
      end
    end

    context 'when CSV has whitespace in email addresses' do
      let(:csv_content) do
        <<~CSV
          name,website,address_line_1,municipality,country_code,owner_email
          Test School,https://test.example.com,123 Main St,Springfield,US,  owner@example.com#{'  '}
        CSV
      end

      let(:csv_file) do
        tempfile = Tempfile.new(['schools_whitespace', '.csv'])
        tempfile.write(csv_content)
        tempfile.rewind
        Rack::Test::UploadedFile.new(tempfile.path, 'text/csv')
      end

      it 'handles whitespace in email addresses' do
        allow(UserInfoApiClient).to receive(:search_by_email).and_return(
          [{ id: SecureRandom.uuid, email: 'owner@example.com' }]
        )
        allow(ImportSchoolsJob).to receive(:perform_later).and_return(instance_double(ImportSchoolsJob, job_id: 'test-job-id'))

        post('/api/schools/import', headers: headers, params: { csv_file: csv_file })

        expect(response).to have_http_status(:accepted)
      end
    end

    context 'when CSV has invalid email format' do
      let(:csv_content) do
        <<~CSV
          name,website,address_line_1,municipality,country_code,owner_email
          Test School,https://test.example.com,123 Main St,Springfield,US,invalid-email
        CSV
      end

      let(:csv_file) do
        tempfile = Tempfile.new(['schools_invalid_email', '.csv'])
        tempfile.write(csv_content)
        tempfile.rewind
        Rack::Test::UploadedFile.new(tempfile.path, 'text/csv')
      end

      it 'rejects CSV with invalid email format' do
        post('/api/schools/import', headers: headers, params: { csv_file: csv_file })

        expect(response).to have_http_status(:unprocessable_entity)
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:error_code]).to eq('CSV_VALIDATION_FAILED')
        expect(data[:details][:row_errors].first[:errors]).to include(
          hash_including(field: 'owner_email', message: 'invalid email format')
        )
      end
    end

    context 'when CSV has special characters' do
      let(:csv_content) do
        <<~CSV
          name,website,address_line_1,municipality,country_code,owner_email
          "School with, comma",https://test.example.com,"123 Main St, Apt 2",Springfield,US,owner@example.com
        CSV
      end

      let(:csv_file) do
        tempfile = Tempfile.new(['schools_special_chars', '.csv'])
        tempfile.write(csv_content)
        tempfile.rewind
        Rack::Test::UploadedFile.new(tempfile.path, 'text/csv')
      end

      it 'handles special characters correctly' do
        allow(UserInfoApiClient).to receive(:search_by_email).and_return(
          [{ id: SecureRandom.uuid, email: 'owner@example.com' }]
        )
        allow(ImportSchoolsJob).to receive(:perform_later).and_return(instance_double(ImportSchoolsJob, job_id: 'test-job-id'))

        post('/api/schools/import', headers: headers, params: { csv_file: csv_file })

        expect(response).to have_http_status(:accepted)
      end
    end

    context 'when CSV file is completely empty' do
      let(:csv_file) do
        tempfile = Tempfile.new(['schools_blank', '.csv'])
        tempfile.write('')
        tempfile.rewind
        Rack::Test::UploadedFile.new(tempfile.path, 'text/csv')
      end

      it 'rejects empty file' do
        post('/api/schools/import', headers: headers, params: { csv_file: csv_file })

        expect(response).to have_http_status(:unprocessable_entity)
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:error_code]).to eq('CSV_INVALID_FORMAT')
        expect(data[:message]).to include('empty')
      end
    end
  end

  describe 'Job Status Access Control' do
    let(:admin_1) { create(:user, roles: 'experience-cs-admin') }
    let(:admin_2) { create(:user, roles: 'experience-cs-admin') }
    let(:job_id) { SecureRandom.uuid }

    before do
      # Create a job result owned by admin1
      SchoolImportResult.create!(
        job_id: job_id,
        user_id: admin_1.id,
        results: { successful: [], failed: [] }
      )

      # Create a GoodJob execution
      GoodJob::Execution.create!(
        active_job_id: job_id,
        job_class: 'ImportSchoolsJob',
        serialized_params: {},
        queue_name: 'import_schools_job',
        created_at: Time.current
      )
    end

    context 'when an admin tries to access another admins job' do
      it 'allows access' do
        authenticated_in_hydra_as(admin_2)

        get("/api/school_import_jobs/#{job_id}", headers: headers)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when a non-admin tries to access an import job' do
      let(:non_admin) { create(:user, roles: '') }

      it 'returns 403' do
        authenticated_in_hydra_as(non_admin)

        get("/api/school_import_jobs/#{job_id}", headers: headers)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
