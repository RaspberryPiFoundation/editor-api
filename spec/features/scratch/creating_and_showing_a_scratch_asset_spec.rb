# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a Scratch asset', type: :request do
  let(:basename) { 'test_image_1' }
  let(:format) { 'png' }
  let(:filename) { "#{basename}.#{format}" }
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:) }
  let(:cookie_headers) { { 'Cookie' => "scratch_auth=#{UserProfileMock::TOKEN}" } }

  describe 'GET #show' do
    let(:make_request) { get '/api/scratch/assets/internalapi/asset/test_image_1.png/get/' }

    context 'when the asset exists' do
      let!(:scratch_asset) { create(:scratch_asset, :with_file, filename:, asset_path: file_fixture(filename)) }

      it 'redirects to the asset file URL' do
        make_request

        expect(response).to redirect_to(rails_storage_redirect_url(scratch_asset.file, only_path: true))
      end
    end
  end

  describe 'POST #create' do
    let(:upload) { File.binread(file_fixture(filename)) }
    let(:make_request) do
      post '/api/scratch/assets/test_image_1.png', headers: { 'Content-Type' => 'application/octet-stream' }.merge(cookie_headers), params: upload
    end

    context 'when user is logged in and cat_mode is enabled' do
      before do
        authenticated_in_hydra_as(teacher)
        Flipper.disable :cat_mode
        Flipper.disable_actor :cat_mode, school
      end

      it 'creates a new asset' do
        # Arrange
        Flipper.enable_actor :cat_mode, school

        # Act & Assert
        expect { make_request }.to change(ScratchAsset, :count).by(1)
      end

      it 'sets the filename on the asset' do
        # Arrange
        Flipper.enable_actor :cat_mode, school

        # Act & Assert
        make_request
        expect(ScratchAsset.last.filename).to eq(filename)
      end

      it 'attaches the uploaded file to the asset' do
        # Arrange
        Flipper.enable_actor :cat_mode, school

        # Act & Assert
        make_request
        expect(ScratchAsset.last.file).to be_attached
      end

      it 'stores the content of the file in the attachment' do
        # Arrange
        Flipper.enable_actor :cat_mode, school

        # Act & Assert
        make_request
        expect(ScratchAsset.last.file.download).to eq(upload)
      end

      it 'responds with 201 Created' do
        # Arrange
        Flipper.enable_actor :cat_mode, school

        # Act & Assert
        make_request
        expect(response).to have_http_status(:created)
      end

      it 'includes the status and filename (without extension) in the response' do
        # Arrange
        Flipper.enable_actor :cat_mode, school

        # Act & Assert
        make_request
        expect(response.parsed_body).to include(
          'status' => 'ok',
          'content-name' => basename
        )
      end

      context 'when the asset already exists' do
        let(:another_upload_path) { file_fixture('test_image_2.jpeg') }
        let(:upload) { File.binread(another_upload_path) }
        let(:original_upload) { File.binread(file_fixture(filename)) }

        before do
          create(:scratch_asset, :with_file, filename:, asset_path: file_fixture(filename))
        end

        it 'does not update the content of the file in the attachment' do
          # Arrange
          Flipper.enable_actor :cat_mode, school

          # Act & Assert
          make_request
          expect(ScratchAsset.last.file.download).to eq(original_upload)
        end

        it 'responds with 201 Created' do
          # Arrange
          Flipper.enable_actor :cat_mode, school

          # Act & Assert
          make_request
          expect(response).to have_http_status(:created)
        end

        it 'includes the status and filename (without extension) in the response' do
          # Arrange
          Flipper.enable_actor :cat_mode, school

          # Act & Assert
          make_request
          expect(response.parsed_body).to include(
            'status' => 'ok',
            'content-name' => basename
          )
        end
      end
    end

    context 'when user is logged in and cat_mode is disabled' do
      before do
        authenticated_in_hydra_as(teacher)
        Flipper.disable :cat_mode
        Flipper.disable_actor :cat_mode, school
      end

      it 'responds 404 Not Found when cat_mode is not enabled' do
        # Act
        post '/api/scratch/assets/example.svg', headers: cookie_headers

        # Assert
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
