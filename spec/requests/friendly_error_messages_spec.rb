# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'FriendlyErrorMessages' do
  describe 'POST /fem' do
    let(:headers) { { Authorization: UserProfileMock::TOKEN } }
    let(:school) { create(:school) }
    let(:student) { create(:student, school:) }

    it 'does not allow logged-out users' do
      post '/api/fem'

      expect(response).to have_http_status(:unauthorized)
    end

    it 'allows logged-in users' do
      authenticated_in_hydra_as(student)

      post('/api/fem', headers:)

      expect(response).to have_http_status(:success)
    end
  end
end
