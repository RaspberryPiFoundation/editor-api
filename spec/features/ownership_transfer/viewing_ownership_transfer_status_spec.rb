# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Viewing ownership transfer status', type: :request do
  include_context 'with a school owner and nominated teacher'

  it 'responds 401 Unauthorized when no token is given' do
    get("/api/schools/#{school.id}/ownership_transfer")
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    student = create(:student, school:)
    authenticated_in_hydra_as(student)

    get("/api/schools/#{school.id}/ownership_transfer", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  context 'when the school has never had an ownership transfer' do
    before { authenticated_in_hydra_as(owner) }

    it 'responds 404 Not Found' do
      get("/api/schools/#{school.id}/ownership_transfer", headers:)
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when there is a pending transfer for the school' do
    let!(:ownership_transfer) do
      create(
        :ownership_transfer,
        school:,
        nominated_user_id: nominee.id,
        requested_by_user_id: owner.id,
        email_address: nominee.email
      )
    end

    context 'when the current user is the school owner' do
      before do
        stub_user_info_api_for(nominee)
        authenticated_in_hydra_as(owner)
      end

      it 'responds 200 OK' do
        get("/api/schools/#{school.id}/ownership_transfer", headers:)
        expect(response).to have_http_status(:ok)
      end

      it 'identifies the current user as the owner' do
        get("/api/schools/#{school.id}/ownership_transfer", headers:)

        json = JSON.parse(response.body)
        expect(json['you_are']).to eq('owner')
      end

      it 'includes the nominated teacher\'s name' do
        get("/api/schools/#{school.id}/ownership_transfer", headers:)

        json = JSON.parse(response.body)
        expect(json['nominee_name']).to eq(nominee.name)
      end

      it 'includes the nominated teacher\'s email' do
        get("/api/schools/#{school.id}/ownership_transfer", headers:)

        json = JSON.parse(response.body)
        expect(json['nominee_email']).to eq(ownership_transfer.email_address)
      end

      it 'includes the transfer status' do
        get("/api/schools/#{school.id}/ownership_transfer", headers:)

        json = JSON.parse(response.body)
        expect(json['status']).to eq('pending')
      end
    end

    context 'when the current user is the nominee' do
      before { authenticated_in_hydra_as(nominee) }

      it 'responds 200 OK' do
        get("/api/schools/#{school.id}/ownership_transfer", headers:)
        expect(response).to have_http_status(:ok)
      end

      it 'identifies the current user as the nominee' do
        get("/api/schools/#{school.id}/ownership_transfer", headers:)

        json = JSON.parse(response.body)
        expect(json['you_are']).to eq('nominee')
      end

      it 'includes the transfer status' do
        get("/api/schools/#{school.id}/ownership_transfer", headers:)

        json = JSON.parse(response.body)
        expect(json['status']).to eq('pending')
      end
    end

    context 'when the current user is a different teacher at the school' do
      let(:other_teacher) { create(:teacher, school:) }

      before { authenticated_in_hydra_as(other_teacher) }

      it_behaves_like 'a hidden ownership transfer'
    end

    context 'when the transfer has completed' do
      before do
        ownership_transfer.update!(status: :completed)
        stub_user_info_api_for(nominee)
        authenticated_in_hydra_as(owner)
      end

      it 'responds 200 OK, still visible to the requester' do
        get("/api/schools/#{school.id}/ownership_transfer", headers:)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to include('status' => 'completed', 'you_are' => 'owner', 'nominee_name' => nominee.name, 'nominee_email' => ownership_transfer.email_address)
      end
    end

    context 'when the transfer was rejected' do
      before do
        ownership_transfer.update!(status: :rejected)
        authenticated_in_hydra_as(nominee)
      end

      it 'responds 200 OK, still visible to the nominee who rejected it' do
        get("/api/schools/#{school.id}/ownership_transfer", headers:)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to include('status' => 'rejected', 'you_are' => 'nominee')
      end
    end

    context 'when the transfer was cancelled' do
      before do
        ownership_transfer.update!(status: :cancelled)
        authenticated_in_hydra_as(nominee)
      end

      it 'responds 200 OK, still visible to the nominee' do
        get("/api/schools/#{school.id}/ownership_transfer", headers:)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to include('status' => 'cancelled', 'you_are' => 'nominee')
      end
    end

    context 'when a resolved transfer is viewed by someone who was never involved' do
      let(:other_teacher) { create(:teacher, school:) }

      before do
        ownership_transfer.update!(status: :completed)
        authenticated_in_hydra_as(other_teacher)
      end

      it_behaves_like 'a hidden ownership transfer'
    end
  end
end
