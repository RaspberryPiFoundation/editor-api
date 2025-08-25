  # frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Importing a school class', type: :request do
  before do
    authenticated_in_hydra_as(teacher)
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

  it 'creates a class when import_origin and import_id are provided' do
    post(import_url, headers:, params: base_import_params)
    expect(response).to have_http_status(:created)
    data = JSON.parse(response.body, symbolize_names: true)
    expect(data[:name]).to eq('Imported Class')
    expect(data[:description]).to eq('Imported Description')
  end

  it 'returns 422 if import_origin is missing' do
    params_missing_origin = base_import_params.deep_dup
    params_missing_origin[:school_class].delete(:import_origin)
    post(import_url, headers:, params: params_missing_origin)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)['error'].to_s).to include("Import origin can't be blank")
  end

  it 'returns 422 if import_id is missing' do
    params_missing_id = base_import_params.deep_dup
    params_missing_id[:school_class].delete(:import_id)
    post(import_url, headers:, params: params_missing_id)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)['error'].to_s).to include("Import can't be blank")
  end

  it 'returns 422 if both import_origin and import_id are missing' do
    params_missing_both = base_import_params.deep_dup
    params_missing_both[:school_class].delete(:import_origin)
    params_missing_both[:school_class].delete(:import_id)
    post(import_url, headers:, params: params_missing_both)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)['error'].to_s).to include("Import origin can't be blank")
  end
end
