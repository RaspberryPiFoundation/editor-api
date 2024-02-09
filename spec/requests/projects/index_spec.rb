# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project index requests' do
  include PaginationLinksMock

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:project_keys) { %w[identifier project_type name user_id updated_at] }

  before do
    create_list(:project, 2, user_id: stubbed_user_id)
  end

  context 'when user is logged in' do
    before do
      # create non user projects
      create_list(:project, 2)
      stub_hydra_public_api
    end

    it 'returns success response' do
      get('/api/projects', headers:)
      expect(response).to have_http_status(:ok)
    end

    it 'returns correct number of projects' do
      get('/api/projects', headers:)
      returned = response.parsed_body
      expect(returned.length).to eq(2)
    end

    it 'returns users projects' do
      get('/api/projects', headers:)
      returned = response.parsed_body
      expect(returned.all? { |proj| proj['user_id'] == stubbed_user_id }).to be(true)
    end

    it 'returns all keys in response' do
      get('/api/projects', headers:)
      returned = response.parsed_body
      returned.each { |project| expect(project.keys).to eq(project_keys) }
    end
  end

  context 'when the projects index has pagination' do
    before do
      stub_hydra_public_api
      create_list(:project, 10, user_id: stubbed_user_id)
    end

    it 'returns the default number of projects on the first page' do
      get('/api/projects', headers:)
      returned = response.parsed_body
      expect(returned.length).to eq(8)
    end

    it 'returns the next set of projects on the next page' do
      get('/api/projects?page=2', headers:)
      returned = response.parsed_body
      expect(returned.length).to eq(4)
    end

    it 'has the correct response headers for the first page' do
      last_link = page_links(2, 'last')
      next_link = page_links(2, 'next')
      expected_link_header = [last_link, next_link].join(', ')

      get('/api/projects', headers:)
      expect(response.headers['Link']).to eq expected_link_header
    end

    it 'has the correct response headers for the next page' do
      first_link = page_links(1, 'first')
      prev_link = page_links(1, 'prev')
      expected_link_header = [first_link, prev_link].join(', ')

      get('/api/projects?page=2', headers:)
      expect(response.headers['Link']).to eq expected_link_header
    end
  end

  context 'when no token is given' do
    it 'returns unauthorized' do
      get '/api/projects'
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
