# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::DefaultProjects' do
  describe 'GET /api/default_project' do
    it 'returns default project' do
      get '/api/default_project'
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /api/default_project/python' do
    it 'returns default Python project' do
      get '/api/default_project/python'
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /api/default_project/html' do
    it 'returns default HTML project' do
      get '/api/default_project/html'
      expect(response).to have_http_status(:ok)
    end
  end
end
