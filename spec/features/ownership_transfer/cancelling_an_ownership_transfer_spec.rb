# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cancelling an ownership transfer', type: :request do
  include ActionMailer::TestHelper

  include_context 'with a school owner and nominated teacher'

  it 'responds 401 Unauthorized when no token is given' do
    put("/api/schools/#{school.id}/ownership_transfer/cancel")
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    student = create(:student, school:)
    authenticated_in_hydra_as(student)

    put("/api/schools/#{school.id}/ownership_transfer/cancel", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is the owner of a different school' do
    other_owner = create(:owner, school: create(:verified_school))
    authenticated_in_hydra_as(other_owner)

    put("/api/schools/#{school.id}/ownership_transfer/cancel", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  context 'when the school has never had an ownership transfer' do
    before { authenticated_in_hydra_as(owner) }

    it 'responds 404 Not Found' do
      put("/api/schools/#{school.id}/ownership_transfer/cancel", headers:)
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

    context 'when the current user is the owner who requested the transfer' do
      before { authenticated_in_hydra_as(owner) }

      it 'responds 200 OK' do
        put("/api/schools/#{school.id}/ownership_transfer/cancel", headers:)
        expect(response).to have_http_status(:ok)
      end

      it 'marks the transfer as cancelled' do
        put("/api/schools/#{school.id}/ownership_transfer/cancel", headers:)
        expect(ownership_transfer.reload.status).to eq('cancelled')
      end

      it 'sends the cancellation email' do
        put("/api/schools/#{school.id}/ownership_transfer/cancel", headers:)

        assert_enqueued_email_with(
          SchoolOwnershipMailer, :cancel_ownership_transfer, params: { ownership_transfer: }
        )
      end
    end

    context 'when the current user is a different owner of the same school' do
      let(:other_owner) { create(:owner, school:) }

      before { authenticated_in_hydra_as(other_owner) }

      it 'responds 200 OK, since any current owner can cancel, not only the one who requested it' do
        put("/api/schools/#{school.id}/ownership_transfer/cancel", headers:)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the current user is the nominee' do
      before { authenticated_in_hydra_as(nominee) }

      it 'responds 404 Not Found, since only an owner of the school can cancel' do
        put("/api/schools/#{school.id}/ownership_transfer/cancel", headers:)
        expect(response).to have_http_status(:not_found)
      end

      it 'does not change the transfer status' do
        put("/api/schools/#{school.id}/ownership_transfer/cancel", headers:)
        expect(ownership_transfer.reload.status).to eq('pending')
      end
    end

    context 'when the current user is a different teacher at the school' do
      let(:other_teacher) { create(:teacher, school:) }

      before { authenticated_in_hydra_as(other_teacher) }

      it 'responds 404 Not Found' do
        put("/api/schools/#{school.id}/ownership_transfer/cancel", headers:)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the transfer is no longer pending' do
      before do
        ownership_transfer.update!(status: :completed)
        authenticated_in_hydra_as(owner)
      end

      it 'responds 404 Not Found' do
        put("/api/schools/#{school.id}/ownership_transfer/cancel", headers:)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the transfer has already been cancelled' do
      before do
        authenticated_in_hydra_as(owner)
        put("/api/schools/#{school.id}/ownership_transfer/cancel", headers:)
      end

      it 'allows the owner to start a new transfer' do
        other_teacher = create(:teacher, school:)
        stub_user_info_api_for(other_teacher)

        post(
          "/api/schools/#{school.id}/ownership_transfer",
          params: { ownership_transfer: { nominated_user_id: other_teacher.id } },
          headers:
        )

        expect(response).to have_http_status(:created)
      end
    end
  end
end
