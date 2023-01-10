# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project index requests', type: :request do
  let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }
  let(:project_keys) { %w[identifier project_type name user_id updated_at] }

  before do
    create_list(:project, 2, user_id:)
  end

  context 'when user is logged in' do
    before do
      # create non user projects
      create_list(:project, 2)
      mock_oauth_user(user_id)
    end

    it 'returns success response' do
      get '/api/projects'
      expect(response).to have_http_status(:ok)
    end

    it 'returns correct number of projects' do
      get '/api/projects'
      returned = JSON.parse(response.body)
      expect(returned.length).to eq(2)
    end

    it 'returns users projects' do
      get '/api/projects'
      returned = JSON.parse(response.body)
      expect(returned.all? { |proj| proj['user_id'] == user_id }).to be(true)
    end

    it 'returns all keys in response' do
      get '/api/projects'
      returned = JSON.parse(response.body)
      returned.each { |project| expect(project.keys).to eq(project_keys) }
    end
  end

  context 'when user has multiple pages worth of projects' do
    before do
      create_list(:project, 10, user_id:)
      mock_oauth_user(user_id)
    end

    it 'returns 8 on the first page' do
      get '/api/projects?page=1'
      returned = JSON.parse(response.body)
      expect(returned.length).to eq(8)
    end

    it 'returns the next 8 projects on next page' do
      get '/api/projects?page=2'
      returned = JSON.parse(response.body)
      expect(returned.length).to eq(4)
    end
  end

  context 'when no user' do
    it 'returns unauthorized' do
      get '/api/projects'
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
