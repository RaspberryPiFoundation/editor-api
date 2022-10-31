# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project index requests', type: :request do
  let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }

  before do
    create_list(:project, 2, user_id: user_id)
  end

  context 'when user is logged in' do
    before do
      # create non user projects
      create_list(:project, 2)
      mock_oauth_user(user_id)
    end

    it 'returns success response' do
      get '/api/projects'
      expect(response.status).to eq(200)
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
  end

  context 'when no user' do
    it 'returns unauthorized' do
      get '/api/projects'
      expect(response.status).to eq(401)
    end
  end
end
