# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin projects', type: :request do
  let(:admin_user) { create(:admin_user) }

  describe 'GET /projects' do
    it 'responds 200' do
      create(:project)

      sign_in_as admin_user

      get "/admin/projects"
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /projects/:id' do
    it 'responds 200 for an internal project' do
      project = create(:internal_project)

      sign_in_as admin_user

      get "/admin/projects/#{project.id}"

      expect(response).to have_http_status(:success)
    end

    it 'responds 404 for a user created project' do
      project = create(:project)

      sign_in_as admin_user

      get "/admin/projects/#{project.id}"

      expect(response).to have_http_status(:not_found)
    end
  end

  private

  def sign_in_as(user)
    allow(User).to receive(:from_omniauth).and_return(admin_user)
    get '/auth/callback'
  end
end
