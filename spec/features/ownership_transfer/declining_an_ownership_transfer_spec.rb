# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Declining an ownership transfer', type: :request do
  include_context 'with a school owner and nominated teacher'

  it 'responds 401 Unauthorized when no token is given' do
    put("/api/schools/#{school.id}/ownership_transfer/decline")
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    student = create(:student, school:)
    authenticated_in_hydra_as(student)

    put("/api/schools/#{school.id}/ownership_transfer/decline", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  context 'when the school has never had an ownership transfer' do
    before { authenticated_in_hydra_as(nominee) }

    it 'responds 404 Not Found' do
      put("/api/schools/#{school.id}/ownership_transfer/decline", headers:)
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

    context 'when the current user is the nominee' do
      before { authenticated_in_hydra_as(nominee) }

      it 'responds 200 OK' do
        put("/api/schools/#{school.id}/ownership_transfer/decline", headers:)
        expect(response).to have_http_status(:ok)
      end

      it 'marks the transfer as rejected' do
        put("/api/schools/#{school.id}/ownership_transfer/decline", headers:)
        expect(ownership_transfer.reload.status).to eq('rejected')
      end
    end

    context 'when the current user is the school owner who requested the transfer' do
      before { authenticated_in_hydra_as(owner) }

      it 'responds 404 Not Found, since only the nominee can decline' do
        put("/api/schools/#{school.id}/ownership_transfer/decline", headers:)
        expect(response).to have_http_status(:not_found)
      end

      it 'does not change the transfer status' do
        put("/api/schools/#{school.id}/ownership_transfer/decline", headers:)
        expect(ownership_transfer.reload.status).to eq('pending')
      end
    end

    context 'when the current user is a different teacher at the school' do
      let(:other_teacher) { create(:teacher, school:) }

      before { authenticated_in_hydra_as(other_teacher) }

      it 'responds 404 Not Found' do
        put("/api/schools/#{school.id}/ownership_transfer/decline", headers:)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the transfer is no longer pending' do
      before do
        ownership_transfer.update!(status: :completed)
        authenticated_in_hydra_as(nominee)
      end

      it 'responds 404 Not Found' do
        put("/api/schools/#{school.id}/ownership_transfer/decline", headers:)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
