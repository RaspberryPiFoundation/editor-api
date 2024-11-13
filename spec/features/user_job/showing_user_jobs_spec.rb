# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Showing user jobs', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:owner) { create(:owner, school:) }

  let(:good_jobs) { create_list(:good_job, 2) }
  let!(:user_jobs) { good_jobs.map { |job| create(:user_job, good_job: job, user_id: owner.id) } }

  before do
    authenticated_in_hydra_as(owner)
  end

  it 'responds 200 OK' do
    get('/api/user_jobs', headers:)
    expect(response).to have_http_status(:ok)
  end

  it 'responds 401 Unauthorized when no token is given' do
    get '/api/user_jobs'
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds with a list of jobs' do
    get('/api/user_jobs', headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:jobs].pluck(:id)).to eq(user_jobs.pluck(:good_job_id))
  end

  it 'responds with the expected job' do
    job_id = user_jobs.first.good_job_id

    get("/api/user_jobs/#{job_id}", headers:)
    data = JSON.parse(response.body, symbolize_names: true)

    expect(data[:job][:id]).to eq(job_id)
  end
end
