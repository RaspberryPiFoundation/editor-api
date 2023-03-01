# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Images requests' do
  let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }
  let(:project) { create(:project, user_id:) }
  let(:image_filename) { 'test_image_1.png' }
  let(:params) { { images: [fixture_file_upload(image_filename, 'image/png')] } }
  let(:expected_json) do
    {
      image_list: [
        {
          filename: image_filename,
          url: rails_blob_url(project.images[0])
        }
      ]
    }.to_json
  end

  describe 'create' do
    context 'when auth is correct' do
      before do
        mock_oauth_user(user_id)
      end

      it 'attaches file to project' do
        expect { post "/api/projects/#{project.identifier}/images", params: }.to change { project.images.count }.by(1)
      end

      it 'returns file list' do
        post("/api/projects/#{project.identifier}/images", params:)

        expect(response.body).to eq(expected_json)
      end

      it 'returns success response' do
        post("/api/projects/#{project.identifier}/images", params:)

        expect(response).to have_http_status(:ok)
      end

      it 'returns 404 response if invalid project' do
        post '/api/projects/no-such-project/images'

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when authed user is not creator' do
      before do
        mock_oauth_user
      end

      it 'returns forbidden response' do
        post("/api/projects/#{project.identifier}/images", params:)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when auth is invalid' do
      it 'returns unauthorized' do
        post "/api/projects/#{project.identifier}/images"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
