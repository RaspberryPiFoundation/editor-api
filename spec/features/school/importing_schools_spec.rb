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
        stub_user_info_api_find_by_email(
          email: 'owner@example.com',
          user: { id: SecureRandom.uuid, email: 'owner@example.com' }
        )
        allow(SchoolImportJob).to receive(:perform_later).and_return(instance_double(SchoolImportJob, job_id: 'test-job-id'))
      end

      it 'accepts CSV file and returns 202 Accepted' do
        post('/api/schools/import', headers:, params: { csv_file: csv_file })

        expect(response).to have_http_status(:accepted)
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:job_id]).to eq('test-job-id')
        expect(data[:total_schools]).to eq(2)
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
        expect(data[:error][:error_code]).to eq('CSV_FILE_REQUIRED')
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
  end

  describe 'GET /api/school_import_jobs/:id' do
    let(:admin_user) { create(:user, roles: 'experience-cs-admin') }
    let(:job_id) { SecureRandom.uuid }

    before do
      authenticated_in_hydra_as(admin_user)
    end

    context 'when job exists and is completed' do
      before do
        GoodJob::Job.create!(
          id: SecureRandom.uuid,
          active_job_id: job_id,
          queue_name: 'import_schools_job',
          job_class: 'SchoolImportJob',
          serialized_params: {},
          created_at: 1.hour.ago,
          finished_at: Time.current
        )

        SchoolImportResult.create!(
          job_id: job_id,
          user_id: admin_user.id,
          results: {
            successful: [{ name: 'Test School', id: SecureRandom.uuid, code: '12-34-56' }],
            failed: []
          }
        )
      end

      it 'returns job status with results' do
        get("/api/school_import_jobs/#{job_id}", headers:)

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body, symbolize_names: true)

        expect(data[:status]).to eq('succeeded')
        expect(data[:results][:successful].count).to eq(1)
      end
    end

    context 'when job does not exist' do
      it 'returns 404' do
        get("/api/school_import_jobs/#{SecureRandom.uuid}", headers:)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when user is not an admin' do
      let(:regular_user) { create(:user) }

      before do
        authenticated_in_hydra_as(regular_user)
      end

      it 'responds 403 Forbidden' do
        get("/api/school_import_jobs/#{job_id}", headers:)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
