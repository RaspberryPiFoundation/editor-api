# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Images requests' do
  let(:project) { create(:project, user_id: owner.id) }
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
  let(:owner) { create(:owner, school:) }
  let(:school) { create(:school) }

  describe 'create' do
    context 'when auth is correct' do
      let(:headers) { { Authorization: UserProfileMock::TOKEN } }

      before do
        authenticated_in_hydra_as(owner)
      end

      it 'attaches file to project' do
        expect { post "/api/projects/#{project.identifier}/images", params:, headers: }.to change { project.images.count }.by(1)
      end

      it 'returns file list' do
        post("/api/projects/#{project.identifier}/images", params:, headers:)

        expect(response.body).to eq(expected_json)
      end

      it 'returns success response' do
        post("/api/projects/#{project.identifier}/images", params:, headers:)

        expect(response).to have_http_status(:ok)
      end

      it 'returns 404 response if invalid project' do
        post('/api/projects/no-such-project/images', headers:)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when authed user is not creator' do
      let(:headers) { { Authorization: UserProfileMock::TOKEN } }
      let(:school) { create(:school) }

      before do
        teacher = create(:teacher, school:)
        authenticated_in_hydra_as(teacher)
      end

      it 'returns forbidden response' do
        post("/api/projects/#{project.identifier}/images", params:, headers:)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when auth token is missing' do
      it 'returns unauthorized' do
        post("/api/projects/#{project.identifier}/images", headers:)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
