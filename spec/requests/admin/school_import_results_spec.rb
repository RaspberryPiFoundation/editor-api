# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::SchoolImportResults' do
  let(:admin_user) { create(:user, roles: 'editor-admin') }

  before do
    allow_any_instance_of(Admin::ApplicationController).to receive(:current_user).and_return(admin_user)

    # Stub UserInfoApiClient to avoid external API calls
    allow(UserInfoApiClient).to receive(:fetch_by_ids).and_return([
                                                                    {
                                                                      id: admin_user.id,
                                                                      name: 'Test Admin',
                                                                      email: 'admin@test.com'
                                                                    }
                                                                  ])
  end

  describe 'GET /admin/school_import_results' do
    it 'returns successfully' do
      get admin_school_import_results_path
      expect(response).to have_http_status(:success)
    end

    context 'with existing import results' do
      let!(:import_result) do
        SchoolImportResult.create!(
          job_id: SecureRandom.uuid,
          user_id: admin_user.id,
          results: { 'successful' => [], 'failed' => [] }
        )
      end

      it 'displays the import results' do
        get admin_school_import_results_path
        expect(response.body).to include('School Import History')
        expect(response.body).to include('Test Admin &lt;admin@test.com&gt;')
      end
    end
  end

  describe 'GET /admin/school_import_results/new' do
    it 'returns successfully' do
      get new_admin_school_import_result_path
      expect(response).to have_http_status(:success)
    end

    it 'displays the upload form' do
      get new_admin_school_import_result_path
      expect(response.body).to include('Upload School Import CSV')
      expect(response.body).to include('csv_file')
    end
  end

  describe 'GET /admin/school_import_results/:id' do
    let(:import_result) do
      SchoolImportResult.create!(
        job_id: SecureRandom.uuid,
        user_id: admin_user.id,
        results: {
          'successful' => [
            { 'name' => 'Test School', 'code' => '12-34-56', 'id' => SecureRandom.uuid, 'owner_email' => 'owner@test.com' }
          ],
          'failed' => []
        }
      )
    end

    it 'returns successfully' do
      get admin_school_import_result_path(import_result)
      expect(response).to have_http_status(:success)
    end

    it 'displays the job details' do
      get admin_school_import_result_path(import_result)
      expect(response.body).to include(import_result.job_id)
      expect(response.body).to include('Test School')
    end

    it 'displays user name and email' do
      get admin_school_import_result_path(import_result)
      expect(response.body).to include('Test Admin &lt;admin@test.com&gt;')
    end

    it 'allows downloading results as CSV' do
      get admin_school_import_result_path(import_result, format: :csv)
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('text/csv')
      expect(response.body).to include('Status,School Name,School Code')
      expect(response.body).to include('Success,Test School,12-34-56')
    end

    context 'with failed schools' do
      let(:import_result_with_failures) do
        SchoolImportResult.create!(
          job_id: SecureRandom.uuid,
          user_id: admin_user.id,
          results: {
            'successful' => [
              { 'name' => 'Good School', 'code' => '11-22-33', 'id' => SecureRandom.uuid, 'owner_email' => 'good@test.com' }
            ],
            'failed' => [
              { 'name' => 'Bad School', 'owner_email' => 'bad@test.com', 'error_code' => 'OWNER_NOT_FOUND', 'error' => 'Owner not found' }
            ]
          }
        )
      end

      it 'includes both successful and failed schools in CSV' do
        get admin_school_import_result_path(import_result_with_failures, format: :csv)
        expect(response.body).to include('Success,Good School,11-22-33')
        expect(response.body).to include('Failed,Bad School')
        expect(response.body).to include('OWNER_NOT_FOUND,Owner not found')
      end
    end
  end

  describe 'POST /admin/school_import_results' do
    let(:csv_content) { "name,website,address_line_1,municipality,country_code,owner_email\nTest,https://test.edu,123 Main,City,US,test@test.com" }
    let(:csv_file) { Rack::Test::UploadedFile.new(StringIO.new(csv_content), 'text/csv', original_filename: 'test.csv') }
    let(:job_id) { SecureRandom.uuid }

    before do
      allow(School::ImportBatch).to receive(:call).and_return(
        OperationResponse.new.tap do |response|
          response[:job_id] = job_id
          response[:total_schools] = 3
        end
      )
    end

    it 'starts an import job' do
      post admin_school_import_results_path, params: { csv_file: csv_file }
      expect(School::ImportBatch).to have_received(:call)
      expect(response).to redirect_to(admin_school_import_results_path)
      expect(flash[:notice]).to include(job_id)
    end

    context 'without a CSV file' do
      it 'shows an error' do
        post admin_school_import_results_path, params: {}
        expect(response).to redirect_to(new_admin_school_import_result_path)
        expect(flash[:error]).to include('CSV file is required')
      end
    end

    context 'when import fails' do
      before do
        allow(School::ImportBatch).to receive(:call).and_return(
          OperationResponse.new.tap do |response|
            response[:error] = {
              message: 'CSV validation failed',
              details: {
                row_errors: [
                  { row: 2, errors: [{ field: 'country_code', message: 'invalid code' }] }
                ]
              }
            }
          end
        )
      end

      it 'shows an error message with details' do
        post admin_school_import_results_path, params: { csv_file: csv_file }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('CSV validation failed')
        expect(response.body).to include('Row Errors')
      end
    end
  end

  describe 'authorization' do
    let(:non_admin_user) { create(:user, roles: nil) }

    before do
      allow_any_instance_of(Admin::ApplicationController).to receive(:current_user).and_return(non_admin_user)
    end

    it 'redirects non-admin users' do
      get admin_school_import_results_path
      expect(response).to redirect_to('/')
    end
  end
end
