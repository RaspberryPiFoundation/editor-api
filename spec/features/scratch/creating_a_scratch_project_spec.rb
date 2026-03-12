# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a Scratch project (remixing)', type: :request do
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:) }
  let(:cookie_headers) { { 'Cookie' => "scratch_auth=#{UserProfileMock::TOKEN}" } }
  let(:params) { { original_id: 'original-project-id', project: { targets: [] }, is_remix: '1' } }

  before do
    Flipper.disable :cat_mode
    Flipper.disable_actor :cat_mode, school
  end

  it 'responds 401 Unauthorized when no cookie is provided' do
    post '/api/scratch/projects', params: params

    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 404 Not Found when cat_mode is not enabled' do
    authenticated_in_hydra_as(teacher)

    post '/api/scratch/projects', params: params, headers: cookie_headers

    expect(response).to have_http_status(:not_found)
  end

  it 'responds 403 Forbidden when not remixing' do
    authenticated_in_hydra_as(teacher)
    Flipper.enable_actor :cat_mode, school

    post '/api/scratch/projects', params: params.merge(is_remix: '0'), headers: cookie_headers

    expect(response).to have_http_status(:forbidden)
  end

  it 'return new project id when cat_mode is enabled and a cookie is provided' do
    authenticated_in_hydra_as(teacher)
    Flipper.enable_actor :cat_mode, school

    post '/api/scratch/projects', params: params, headers: cookie_headers

    expect(response).to have_http_status(:ok)

    data = JSON.parse(response.body, symbolize_names: true)
    expect(data[:status]).to eq('ok')
    expect(data[:'content-name']).to eq('new-project-id')
  end
end
