# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Images requests', type: :request do
  let!(:project) { create(:project) }
  let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }
  let(:image_filename) {'test_image_1.png' }
  let(:params) { { images: [fixture_file_upload('test_image_1.png', 'image/png')] } }
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
    before do
      mock_phrase_generation
    end

    context 'when auth is correct' do
      before do
        mock_oauth_user
      end

      it 'returns success response' do
        expect {
          post "/api/projects/#{project.identifier}/images", params: params
        }.to change{ project.images.count }.by(1)

        expect(response.status).to eq(200)
        expect(response.body).to eq(expected_json)
      end

      it 'returns 404 response if invalid project' do
        post '/api/projects/no-such-project/images'

        expect(response.status).to eq(404)
      end
    end

    context 'when auth is invalid' do
      it 'returns unauthorized' do
        post "/api/projects/#{project.identifier}/images"

        expect(response.status).to eq(401)
      end
    end
  end
end