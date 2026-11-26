# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Importing a school class', :inline_jobs, type: :request do
  before do
    authenticated_in_hydra_as(teacher)
    stub_user_info_api_for(teacher)
    stub_profile_api_create_safeguarding_flag
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:, name: 'School Teacher') }

  let(:import_url) { "/api/schools/#{school.id}/classes/import" }
  let(:base_import_params) do
    {
      school_class: {
        name: 'Imported Class',
        description: 'Imported Description',
        import_origin: 'google_classroom',
        import_id: 'classroom_123'
      },
      async: '1'
    }
  end

  let(:import_params_with_students) do
    base_import_params.merge(
      school_students: [
        { name: 'Jane Student', email: 'jane.student@example.com' },
        { name: 'John Student', email: 'john.student@example.com' }
      ]
    )
  end

  describe 'School class creation errors' do
    it 'returns 422 if import_origin is missing' do
      params_missing_origin = base_import_params.deep_dup
      params_missing_origin[:school_class].delete(:import_origin)

      post(import_url, headers:, params: params_missing_origin)

      expect(response).to have_http_status(:unprocessable_content)
      error_response = JSON.parse(response.body)
      expect(error_response).to have_key('error')
      expect(error_response['error']).to include("Import origin can't be blank")
    end

    it 'returns 422 if import_id is missing' do
      params_missing_id = base_import_params.deep_dup
      params_missing_id[:school_class].delete(:import_id)

      post(import_url, headers:, params: params_missing_id)

      expect(response).to have_http_status(:unprocessable_content)
      error_response = JSON.parse(response.body)
      expect(error_response).to have_key('error')
      expect(error_response['error']).to include("Import id can't be blank")
    end

    it 'returns 422 if both import_origin and import_id are missing' do
      params_missing_both = base_import_params.deep_dup
      params_missing_both[:school_class].delete(:import_origin)
      params_missing_both[:school_class].delete(:import_id)

      post(import_url, headers:, params: params_missing_both)

      expect(response).to have_http_status(:unprocessable_content)
      error_response = JSON.parse(response.body)
      expect(error_response).to have_key('error')
      expect(error_response['error']).to include("Import origin can't be blank")
    end

    it 'returns 422 if import_origin is invalid' do
      params_invalid_enum = base_import_params.deep_dup
      params_invalid_enum[:school_class][:import_origin] = 'not_a_valid_origin'

      post(import_url, headers:, params: params_invalid_enum)

      expect(response).to have_http_status(:unprocessable_content)
      error_response = JSON.parse(response.body)
      expect(error_response).to have_key('error')
      expect(error_response['error']).to include('Import origin is not included in the list')
    end

    it 'returns 422 if class name is missing' do
      params_missing_name = base_import_params.deep_dup
      params_missing_name[:school_class].delete(:name)

      post(import_url, headers:, params: params_missing_name)

      expect(response).to have_http_status(:unprocessable_content)
      error_response = JSON.parse(response.body)
      expect(error_response).to have_key('error')
      expect(error_response['error']).to include("Name can't be blank")
    end
  end

  describe 'Successful import scenarios' do
    it 'successfully imports a class without students' do
      post(import_url, headers:, params: base_import_params)

      expect(response).to have_http_status(:created)
      response_data = JSON.parse(response.body, symbolize_names: true)

      # School class should be created
      expect(response_data[:school_class]).to include(
        name: 'Imported Class',
        description: 'Imported Description',
        import_origin: 'google_classroom',
        import_id: 'classroom_123'
      )

      # Teachers should be included
      expect(response_data[:school_class][:teachers]).to be_an(Array)
      expect(response_data[:school_class][:teachers].first[:name]).to eq('School Teacher')

      expect(school.roles.student.count).to eq(0)
    end

    it 'successfully imports a class with students and assigns them' do
      student_1_id = SecureRandom.uuid
      student_2_id = SecureRandom.uuid
      profile_response = [
        { id: student_1_id, name: 'Jane Student', success: true },
        { id: student_2_id, name: 'John Student', success: true }
      ]
      allow(ProfileApiClient).to receive(:create_school_students_sso).and_return(profile_response)
      post(import_url, headers:, params: import_params_with_students)

      expect(response).to have_http_status(:created)
      response_data = JSON.parse(response.body, symbolize_names: true)

      expect(response_data[:school_class]).to include(
        name: 'Imported Class',
        description: 'Imported Description',
        import_origin: 'google_classroom',
        import_id: 'classroom_123'
      )
      school_class = SchoolClass.find_by(import_id: 'classroom_123')
      students = school_class.students
      expect(school_class.students.count).to eq(2)
      expect(students.map(&:student_id)).to contain_exactly(student_1_id, student_2_id)
    end

    it 'allows re-importing the same class (finds existing class)' do
      # First import should create the class
      post(import_url, headers:, params: base_import_params)
      expect(response).to have_http_status(:created)
      first_response_data = JSON.parse(response.body, symbolize_names: true)

      # Second import with the same import_id should find the existing class
      post(import_url, headers:, params: base_import_params)
      expect(response).to have_http_status(:created)
      second_response_data = JSON.parse(response.body, symbolize_names: true)

      # Should return the same class
      expect(second_response_data[:school_class][:id]).to eq(first_response_data[:school_class][:id])
      expect(second_response_data[:school_class][:name]).to eq('Imported Class')
    end

    it 'returns the correct JSON structure for successful import' do
      post(import_url, headers:, params: base_import_params)

      expect(response).to have_http_status(:created)
      response_data = JSON.parse(response.body, symbolize_names: true)

      # Verify the complete structure matches the import template
      expect(response_data).to have_key(:school_class)

      # School class structure
      expect(response_data[:school_class]).to include(
        :id, :name, :description, :school_id, :code,
        :created_at, :updated_at, :import_origin, :import_id, :teachers
      )
    end
  end

  describe 'Edge cases' do
    it 'handles empty students array gracefully' do
      params_with_empty_students = base_import_params.merge(school_students: [])

      post(import_url, headers:, params: params_with_empty_students)

      expect(response).to have_http_status(:created)
      response_data = JSON.parse(response.body, symbolize_names: true)

      expect(response_data[:school_class][:name]).to eq('Imported Class')
    end

    it 'handles nil students gracefully' do
      params_with_nil_students = base_import_params.merge(school_students: nil)

      post(import_url, headers:, params: params_with_nil_students)

      expect(response).to have_http_status(:created)
      response_data = JSON.parse(response.body, symbolize_names: true)

      # Should still create the class successfully
      expect(response_data[:school_class][:name]).to eq('Imported Class')
    end
  end
end
