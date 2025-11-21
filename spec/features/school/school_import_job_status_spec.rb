# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'School Import Job Status', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:admin_user) { create(:user, roles: 'experience-cs-admin') }
  let(:job_id) { SecureRandom.uuid }

  before do
    authenticated_in_hydra_as(admin_user)
  end

  describe 'GET /api/school_import_jobs/:id' do
    context 'when job exists and is queued' do
      before do
        GoodJob::Execution.create!(
          id: SecureRandom.uuid, # Execution ID (internal)
          active_job_id: job_id, # ActiveJob ID (what user receieves from API call)
          queue_name: 'import_schools_job',
          job_class: 'ImportSchoolsJob',
          serialized_params: {},
          created_at: Time.current,
          performed_at: nil,
          finished_at: nil
        )
        SchoolImportResult.create!(
          job_id: job_id,
          user_id: admin_user.id,
          results: { successful: [], failed: [] }
        )
      end

      it 'returns job status' do
        get("/api/school_import_jobs/#{job_id}", headers: headers)

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body, symbolize_names: true)

        expect(data[:id]).to eq(job_id)
        expect(data[:status]).to be_in(%w[queued running]) # Either is acceptable
        expect(data[:job_class]).to eq('ImportSchoolsJob')
      end
    end

    context 'when job is completed with results' do
      let(:active_job_id) { SecureRandom.uuid }

      before do
        GoodJob::Execution.create!(
          id: SecureRandom.uuid,
          active_job_id: active_job_id,
          queue_name: 'import_schools_job',
          job_class: 'ImportSchoolsJob',
          serialized_params: {},
          created_at: 1.hour.ago,
          finished_at: Time.current
        )

        SchoolImportResult.create!(
          job_id: active_job_id,
          user_id: admin_user.id,
          results: {
            successful: [
              { name: 'Test School', id: SecureRandom.uuid, code: '12-34-56' }
            ],
            failed: []
          }
        )
      end

      it 'returns job status with results' do
        get("/api/school_import_jobs/#{active_job_id}", headers: headers)

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body, symbolize_names: true)

        expect(data[:status]).to eq('completed')
        expect(data[:results]).to be_present
        expect(data[:results][:successful].count).to eq(1)
        expect(data[:results][:failed].count).to eq(0)
      end
    end

    context 'when job failed' do
      before do
        GoodJob::Execution.create!(
          id: SecureRandom.uuid,
          active_job_id: job_id,
          queue_name: 'import_schools_job',
          job_class: 'ImportSchoolsJob',
          serialized_params: {
            'arguments' => [{ 'user_id' => admin_user.id }]
          },
          error: 'Something went wrong',
          created_at: 1.hour.ago,
          finished_at: Time.current
        )
      end

      it 'returns job status with error' do
        get("/api/school_import_jobs/#{job_id}", headers: headers)

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body, symbolize_names: true)

        expect(data[:status]).to eq('failed')
        expect(data[:error]).to eq('Something went wrong')
      end
    end

    context 'when job does not exist' do
      it 'returns 404' do
        get("/api/school_import_jobs/#{SecureRandom.uuid}", headers: headers)

        expect(response).to have_http_status(:not_found)
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:error_code]).to eq('JOB_NOT_FOUND')
      end
    end

    context 'when job is not an import job' do
      before do
        GoodJob::Execution.create!(
          id: SecureRandom.uuid,
          active_job_id: job_id,
          queue_name: 'default',
          job_class: 'SomeOtherJob',
          serialized_params: {},
          created_at: Time.current
        )
      end

      it 'returns 404' do
        get("/api/school_import_jobs/#{job_id}", headers: headers)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when user is not an admin' do
      let(:regular_user) { create(:user) }

      before do
        GoodJob::Execution.create!(
          id: SecureRandom.uuid,
          active_job_id: job_id,
          queue_name: 'import_schools_job',
          job_class: 'ImportSchoolsJob',
          serialized_params: {},
          created_at: Time.current
        )
        authenticated_in_hydra_as(regular_user)
      end

      it 'responds 403 Forbidden' do
        get("/api/school_import_jobs/#{job_id}", headers: headers)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is an editor-admin' do
      let(:editor_admin) { create(:user, roles: 'editor-admin') }

      before do
        GoodJob::Execution.create!(
          id: SecureRandom.uuid,
          active_job_id: job_id,
          queue_name: 'import_schools_job',
          job_class: 'ImportSchoolsJob',
          serialized_params: {},
          created_at: Time.current
        )
        authenticated_in_hydra_as(editor_admin)
      end

      it 'allows checking job status' do
        get("/api/school_import_jobs/#{job_id}", headers: headers)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user is not authenticated' do
      before do
        unauthenticated_in_hydra
      end

      it 'returns 401' do
        get("/api/school_import_jobs/#{job_id}", headers: {})

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
