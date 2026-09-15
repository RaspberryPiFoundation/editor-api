# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating an ownership transfer', type: :request do
  include ActionMailer::TestHelper

  include_context 'with a school owner and nominated teacher'

  let(:params) { { ownership_transfer: { nominated_user_id: nominee.id } } }

  before do
    stub_user_info_api_for(nominee)
  end

  it 'responds 401 Unauthorized when no token is given' do
    post("/api/schools/#{school.id}/ownership_transfer", params:)
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-teacher' do
    authenticated_in_hydra_as(nominee)

    post("/api/schools/#{school.id}/ownership_transfer", params:, headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    student = create(:student, school:)
    authenticated_in_hydra_as(student)

    post("/api/schools/#{school.id}/ownership_transfer", params:, headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is the owner of a different school' do
    authenticated_in_hydra_as(owner)
    Role.owner.find_by(user_id: owner.id, school:).delete
    Role.teacher.find_by(user_id: nominee.id, school:).delete
    school.update!(id: SecureRandom.uuid)

    post("/api/schools/#{school.id}/ownership_transfer", params:, headers:)
    expect(response).to have_http_status(:forbidden)
  end

  context 'when the current user is the school owner' do
    before { authenticated_in_hydra_as(owner) }

    context 'when the nominee has the teacher role at the school' do
      it 'responds 201 Created' do
        post("/api/schools/#{school.id}/ownership_transfer", params:, headers:)
        expect(response).to have_http_status(:created)
      end

      it 'creates an ownership transfer for the nominee' do
        expect do
          post("/api/schools/#{school.id}/ownership_transfer", params:, headers:)
        end.to change(OwnershipTransfer, :count).by(1)

        expect(OwnershipTransfer.last).to have_attributes(
          school:,
          nominated_user_id: nominee.id,
          requested_by_user_id: owner.id,
          email_address: nominee.email,
          status: 'pending'
        )
      end

      it 'sends the ownership transfer request email' do
        post("/api/schools/#{school.id}/ownership_transfer", params:, headers:)

        assert_enqueued_email_with(
          SchoolOwnershipMailer,
          :request_ownership_transfer,
          params: { ownership_transfer: OwnershipTransfer.last }
        )
      end
    end

    context 'when the nominee does not have the owner or teacher role at the school' do
      let(:params) { { ownership_transfer: { nominated_user_id: SecureRandom.uuid } } }

      it 'responds 422 Unprocessable entity' do
        post("/api/schools/#{school.id}/ownership_transfer", params:, headers:)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'does not create an ownership transfer' do
        expect do
          post("/api/schools/#{school.id}/ownership_transfer", params:, headers:)
        end.not_to change(OwnershipTransfer, :count)
      end
    end

    context 'when a transfer is already pending for the school' do
      before { create(:ownership_transfer, school:, nominated_user_id: nominee.id) }

      it 'responds 422 Unprocessable entity' do
        post("/api/schools/#{school.id}/ownership_transfer", params:, headers:)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'does not create a second ownership transfer' do
        expect do
          post("/api/schools/#{school.id}/ownership_transfer", params:, headers:)
        end.not_to change(OwnershipTransfer, :count)
      end
    end

    context 'when a transfer for the school is no longer pending' do
      before { create(:ownership_transfer, school:, nominated_user_id: nominee.id, status: :completed) }

      it 'responds 201 Created' do
        post("/api/schools/#{school.id}/ownership_transfer", params:, headers:)
        expect(response).to have_http_status(:created)
      end

      it 'creates a new ownership transfer' do
        expect do
          post("/api/schools/#{school.id}/ownership_transfer", params:, headers:)
        end.to change(OwnershipTransfer, :count).by(1)
      end
    end
  end
end
