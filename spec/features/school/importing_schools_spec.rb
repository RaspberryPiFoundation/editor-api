# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Importing schools', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }

  let(:csv_content) do
    <<~CSV
      name,website,address_line_1,municipality,country_code,owner_email
      Test School 1,https://test1.example.com,123 Main St,Springfield,US,owner1@example.com
      Test School 2,https://test2.example.com,456 Oak Ave,Boston,US,owner2@example.com
    CSV
  end

  describe 'POST /api/schools/import' do
    let(:csv_file) do
      tempfile = Tempfile.new(['schools', '.csv'])
      tempfile.write(csv_content)
      tempfile.rewind
      Rack::Test::UploadedFile.new(tempfile.path, 'text/csv')
    end

    context 'when user is an experience_cs_admin' do
      let(:admin_user) { create(:user, roles: 'experience-cs-admin') }

      before do
        authenticated_in_hydra_as(admin_user)
        allow(UserInfoApiClient).to receive(:search_by_email).and_return([{ id: SecureRandom.uuid, email: 'owner@example.com' }])
        allow(ImportSchoolsJob).to receive(:perform_later).and_return(instance_double(ImportSchoolsJob, job_id: 'test-job-id'))
      end

      it 'accepts CSV file and returns 202 Accepted' do
        post('/api/schools/import', headers:, params: { csv_file: csv_file })

        expect(response).to have_http_status(:accepted)
      end

      it 'responds with job_id and total_schools' do
        post('/api/schools/import', headers:, params: { csv_file: csv_file })

        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:job_id]).to eq('test-job-id')
        expect(data[:total_schools]).to eq(2)
        expect(data[:message]).to include('Import job started')
      end

      it 'enqueues ImportSchoolsJob' do
        post('/api/schools/import', headers:, params: { csv_file: csv_file })

        expect(ImportSchoolsJob).to have_received(:perform_later)
      end
    end

    context 'when CSV file is missing' do
      let(:admin_user) { create(:user, roles: 'experience-cs-admin') }

      before do
        authenticated_in_hydra_as(admin_user)
      end

      it 'responds 422 Unprocessable Entity' do
        post('/api/schools/import', headers:)

        expect(response).to have_http_status(:unprocessable_entity)
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:error_code]).to eq('CSV_FILE_REQUIRED')
      end
    end

    context 'when CSV is invalid' do
      let(:admin_user) { create(:user, roles: 'experience-cs-admin') }
      let(:invalid_csv_content) do
        <<~CSV
          name,website
          Test School,https://test.example.com
        CSV
      end
      let(:invalid_csv_file) do
        tempfile = Tempfile.new(['schools_invalid', '.csv'])
        tempfile.write(invalid_csv_content)
        tempfile.rewind
        Rack::Test::UploadedFile.new(tempfile.path, 'text/csv')
      end

      before do
        authenticated_in_hydra_as(admin_user)
      end

      it 'responds 422 Unprocessable Entity with validation errors' do
        post('/api/schools/import', headers:, params: { csv_file: invalid_csv_file })

        expect(response).to have_http_status(:unprocessable_entity)
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:error_code]).to eq('CSV_INVALID_FORMAT')
      end
    end

    context 'when user is not an admin' do
      let(:regular_user) { create(:user, roles: '') }

      before do
        authenticated_in_hydra_as(regular_user)
      end

      it 'responds 403 Forbidden' do
        post('/api/schools/import', headers:, params: { csv_file: csv_file })

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is an editor-admin' do
      let(:admin_user) { create(:user, roles: 'editor-admin') }

      before do
        authenticated_in_hydra_as(admin_user)
        allow(UserInfoApiClient).to receive(:search_by_email).and_return([{ id: SecureRandom.uuid, email: 'owner@example.com' }])
      end

      it 'allows importing schools' do
        post('/api/schools/import', headers:, params: { csv_file: csv_file })

        expect(response).to have_http_status(:accepted)
      end
    end
  end
end
