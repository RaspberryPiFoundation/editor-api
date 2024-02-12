# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing school classes', type: :request do
  before do
    stub_hydra_public_api
    stub_user_info_api

    create(:class_member, school_class:)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:school_class) { create(:school_class, name: 'Test School Class') }
  let(:school) { school_class.school }
  let(:user_id) { stubbed_user_id }

  it 'responds 200 OK' do
    get("/api/schools/#{school.id}/classes", headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds with the school classes JSON' do
    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.first[:name]).to eq('Test School Class')
  end

  it "does not include school classes that the school-teacher doesn't teach" do
    stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))
    create(:school_class, school:, teacher_id: SecureRandom.uuid)

    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(1)
  end

  it "does not include school classes that the school-student isn't a member of" do
    stub_hydra_public_api(user_index: user_index_by_role('school-student'))
    create(:school_class, school:, teacher_id: SecureRandom.uuid)

    get("/api/schools/#{school.id}/classes", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data.size).to eq(1)
  end

  it 'responds 401 Unauthorized when no token is given' do
    get "/api/schools/#{school.id}/classes"
    expect(response).to have_http_status(:unauthorized)
  end
end
