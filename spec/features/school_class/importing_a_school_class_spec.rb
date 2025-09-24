# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Importing a school class', type: :request do
  before do
    authenticated_in_hydra_as(teacher)
    stub_user_info_api_for(teacher)
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
      }
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

      expect(response).to have_http_status(:unprocessable_entity)
      error_response = JSON.parse(response.body)
      expect(error_response).to have_key('error')
      expect(error_response['error']).to include("Import origin can't be blank")
    end

    it 'returns 422 if import_id is missing' do
      params_missing_id = base_import_params.deep_dup
      params_missing_id[:school_class].delete(:import_id)

      post(import_url, headers:, params: params_missing_id)

      expect(response).to have_http_status(:unprocessable_entity)
      error_response = JSON.parse(response.body)
      expect(error_response).to have_key('error')
      expect(error_response['error']).to include("Import id can't be blank")
    end

    it 'returns 422 if both import_origin and import_id are missing' do
      params_missing_both = base_import_params.deep_dup
      params_missing_both[:school_class].delete(:import_origin)
      params_missing_both[:school_class].delete(:import_id)

      post(import_url, headers:, params: params_missing_both)

      expect(response).to have_http_status(:unprocessable_entity)
      error_response = JSON.parse(response.body)
      expect(error_response).to have_key('error')
      expect(error_response['error']).to include("Import origin can't be blank")
    end

    it 'returns 422 if import_origin is invalid' do
      params_invalid_enum = base_import_params.deep_dup
      params_invalid_enum[:school_class][:import_origin] = 'not_a_valid_origin'

      post(import_url, headers:, params: params_invalid_enum)

      expect(response).to have_http_status(:unprocessable_entity)
      error_response = JSON.parse(response.body)
      expect(error_response).to have_key('error')
      expect(error_response['error']).to include('Import origin is not included in the list')
    end

    it 'returns 422 if class name is missing' do
      params_missing_name = base_import_params.deep_dup
      params_missing_name[:school_class].delete(:name)

      post(import_url, headers:, params: params_missing_name)

      expect(response).to have_http_status(:unprocessable_entity)
      error_response = JSON.parse(response.body)
      expect(error_response).to have_key('error')
      expect(error_response['error']).to include("Name can't be blank")
    end
  end

  describe 'Student creation errors' do
    before do
      # Mock student creation to return errors
      student_creation_error_result = OperationResponse.new
      student_creation_error_result[:school_students] = []
      student_creation_error_result[:errors] = {
        'jane.student@example.com' => 'Email already exists',
        'john.student@example.com' => 'Invalid email format'
      }
      allow(SchoolStudent::CreateBatchSSO).to receive(:call).and_return(student_creation_error_result)
    end

    it 'returns 201 with plural [:errors] in students section when student creation fails' do
      post(import_url, headers:, params: import_params_with_students)

      expect(response).to have_http_status(:created)
      response_data = JSON.parse(response.body, symbolize_names: true)

      # School class should be created successfully
      expect(response_data[:school_class][:name]).to eq('Imported Class')
      expect(response_data[:school_class][:description]).to eq('Imported Description')

      # Students section should contain errors
      expect(response_data[:students]).to have_key(:errors)
      expect(response_data[:students][:errors]).to include(
        'jane.student@example.com': 'Email already exists',
        'john.student@example.com': 'Invalid email format'
      )

      # Class members should be empty since no students were created
      expect(response_data[:class_members]).to eq([])
    end
  end

  describe 'Class member creation errors' do
    let(:mock_students) do
      [
        { id: 'student-1-id', name: 'Jane Student', email: 'jane.student@example.com' },
        { id: 'student-2-id', name: 'John Student', email: 'john.student@example.com' }
      ].map do |student_data|
        # Create the new structure with User objects and metadata using factories
        {
          student: build_stubbed(:student, student_data),
          success: true,
          error: nil,
          created: true
        }
      end
    end

    before do
      # Mock successful student creation
      # Mock successful student creation but failed class assignment
      student_creation_result = OperationResponse.new
      student_creation_result[:school_students] = [
        {
          student: build_stubbed(:student, id: 'student-1-id', name: 'Jane Student', email: 'jane.student@example.com'),
          success: true,
          error: nil,
          created: true
        },
        {
          student: build_stubbed(:student, id: 'student-2-id', name: 'John Student', email: 'john.student@example.com'),
          success: true,
          error: nil,
          created: true
        }
      ]
      student_creation_result[:errors] = nil
      allow(SchoolStudent::CreateBatchSSO).to receive(:call).and_return(student_creation_result)

      # Mock class member creation to return errors
      class_member_creation_result = OperationResponse.new
      class_member_creation_result[:class_members] = []
      class_member_creation_result[:errors] = {
        'aa7b5a78-2bd7-4676-8184-318f09a7c494' => 'Error creating class member'
      }
      allow(ClassMember::Create).to receive(:call).and_return(class_member_creation_result)
    end

    it 'returns 201 errors in class_members section when assignment fails' do
      post(import_url, headers:, params: import_params_with_students)

      expect(response).to have_http_status(:created)
      response_data = JSON.parse(response.body, symbolize_names: true)

      # School class should be created successfully
      expect(response_data[:school_class][:name]).to eq('Imported Class')

      # Students should be created successfully
      expect(response_data[:students]).to be_an(Array)
      expect(response_data[:students].length).to eq(2)

      # Class members section should contain errors
      expect(response_data[:class_members]).to be_an(Array)
      expect(response_data[:class_members].length).to eq(1)
      expect(response_data[:class_members].first[:success]).to eq(false)
      expect(response_data[:class_members].first[:student_id]).to eq('aa7b5a78-2bd7-4676-8184-318f09a7c494')
      expect(response_data[:class_members].first[:error]).to eq('Error creating class member')
    end
  end

  describe 'Successful import scenarios' do
    let(:mock_successful_students) do
      [
        {
          student: build_stubbed(:student, id: 'student-1-id', name: 'Jane Student', email: 'jane.student@example.com'),
          success: true,
          error: nil,
          created: true
        },
        {
          student: build_stubbed(:student, id: 'student-2-id', name: 'John Student', email: 'john.student@example.com'),
          success: true,
          error: nil,
          created: true
        }
      ]
    end

    let(:mock_successful_class_members) do
      # Use factories to create proper test objects without database persistence
      student_1 = build_stubbed(:student, id: 'student-1-id', name: 'Jane Student', username: 'jane.student', email: 'jane@example.com')
      student_2 = build_stubbed(:student, id: 'student-2-id', name: 'John Student', username: 'john.student', email: 'john@example.com')

      [
        build_stubbed(:class_student,
                      id: 'member-1-id',
                      school_class_id: 'class-1-id',
                      student_id: 'student-1-id',
                      student: student_1),
        build_stubbed(:class_student,
                      id: 'member-2-id',
                      school_class_id: 'class-1-id',
                      student_id: 'student-2-id',
                      student: student_2)
      ]
    end

    before do
      # Mock successful student creation with new structure
      student_success_result = OperationResponse.new
      student_success_result[:school_students] = mock_successful_students
      student_success_result[:errors] = nil
      allow(SchoolStudent::CreateBatchSSO).to receive(:call).and_return(student_success_result)

      # Mock successful class member creation
      class_member_success_result = OperationResponse.new
      class_member_success_result[:class_members] = mock_successful_class_members
      class_member_success_result[:errors] = {}
      allow(ClassMember::Create).to receive(:call).and_return(class_member_success_result)
    end

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

      # Students and class_members should be empty arrays
      expect(response_data[:students]).to eq([])
      expect(response_data[:class_members]).to eq([])
    end

    it 'successfully imports a class with students and assigns them' do
      post(import_url, headers:, params: import_params_with_students)

      expect(response).to have_http_status(:created)
      response_data = JSON.parse(response.body, symbolize_names: true)

      # School class should be created
      expect(response_data[:school_class]).to include(
        name: 'Imported Class',
        description: 'Imported Description',
        import_origin: 'google_classroom',
        import_id: 'classroom_123'
      )

      # Students should be created successfully
      expect(response_data[:students]).to be_an(Array)
      expect(response_data[:students].length).to eq(2)
      response_data[:students].each do |student|
        expect(student).to include(
          success: true,
          created: true
        )
        expect(student[:error]).to be_nil
      end

      # Class members should be assigned successfully
      expect(response_data[:class_members]).to be_an(Array)
      expect(response_data[:class_members].length).to eq(2)
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
      post(import_url, headers:, params: import_params_with_students)

      expect(response).to have_http_status(:created)
      response_data = JSON.parse(response.body, symbolize_names: true)

      # Verify the complete structure matches the import template
      expect(response_data).to have_key(:school_class)
      expect(response_data).to have_key(:students)
      expect(response_data).to have_key(:class_members)

      # School class structure
      expect(response_data[:school_class]).to include(
        :id, :name, :description, :school_id, :code,
        :created_at, :updated_at, :import_origin, :import_id, :teachers
      )

      # Students structure (array when successful)
      expect(response_data[:students]).to be_an(Array)

      # Class members structure (array when successful)
      expect(response_data[:class_members]).to be_an(Array)
    end
  end

  describe 'Edge cases' do
    it 'handles empty students array gracefully' do
      params_with_empty_students = base_import_params.merge(school_students: [])

      post(import_url, headers:, params: params_with_empty_students)

      expect(response).to have_http_status(:created)
      response_data = JSON.parse(response.body, symbolize_names: true)

      expect(response_data[:school_class][:name]).to eq('Imported Class')
      expect(response_data[:students]).to eq([])
      expect(response_data[:class_members]).to eq([])
    end

    it 'handles nil students gracefully' do
      params_with_nil_students = base_import_params.merge(school_students: nil)

      post(import_url, headers:, params: params_with_nil_students)

      expect(response).to have_http_status(:created)
      response_data = JSON.parse(response.body, symbolize_names: true)

      # Should still create the class successfully
      expect(response_data[:school_class][:name]).to eq('Imported Class')
      expect(response_data[:students]).to eq([])
      expect(response_data[:class_members]).to eq([])
    end
  end
end
