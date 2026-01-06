# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Schools', type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    sign_in_as(admin_user)
  end

  describe 'GET #index' do
    it 'responds 200' do
      get admin_schools_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #show' do
    let(:creator) { create(:user) }
    let(:verified_at) { nil }
    let(:rejected_at) { nil }
    let(:code) { nil }
    let(:school) { create(:school, creator_id: creator.id, verified_at:, rejected_at:, code:) }

    before do
      stub_user_info_api_for(creator)
      get admin_school_path(school)
    end

    it 'responds 200' do
      expect(response).to have_http_status(:success)
    end

    it 'includes link to verify school' do
      expect(response.body).to include(I18n.t('administrate.actions.verify_school'))
    end

    it 'includes link to reject school' do
      expect(response.body).to include(I18n.t('administrate.actions.reject_school'))
    end

    it 'does not include a link to search for this school by its ZIP code in the NCES public schools database' do
      expect(response.body).not_to include('Search for this school in the NCES database')
    end

    describe 'when the school is verified' do
      let(:verified_at) { Time.zone.now }
      let(:code) { '00-00-00' }

      it 'does not include a link to verify school' do
        expect(response.body).not_to include(I18n.t('administrate.actions.verify_school'))
      end

      it 'does not include a link to reject school' do
        expect(response.body).not_to include(I18n.t('administrate.actions.reject_school'))
      end

      it 'does not include a link to reopen school' do
        expect(response.body).not_to include(I18n.t('administrate.actions.reopen_school'))
      end
    end

    describe 'when the school is rejected' do
      let(:rejected_at) { Time.zone.now }

      it 'does not include a link to verify school' do
        expect(response.body).not_to include(I18n.t('administrate.actions.verify_school'))
      end

      it 'does not include a link to reject school' do
        expect(response.body).not_to include(I18n.t('administrate.actions.reject_school'))
      end

      it 'includes link to reopen school' do
        expect(response.body).to include(I18n.t('administrate.actions.reopen_school'))
      end
    end

    describe 'when the school is in the United States and has a postal code' do
      before do
        school.update(country_code: 'US', postal_code: '90210', district_name: 'Some District', district_nces_id: '010000000001', reference: nil)
        get admin_school_path(school)
      end

      it 'includes a link to search for this school by its ZIP code in the NCES public schools database' do
        expect(response.body).to include('Search for this school in the NCES database')
      end
    end
  end

  describe 'POST #verify' do
    let(:creator) { create(:user) }
    let(:verified_at) { nil }
    let(:school) { create(:school, creator_id: creator.id, verified_at:) }
    let(:verification_result) { nil }
    let(:verification_service) { instance_double(SchoolVerificationService, verify: verification_result) }

    before do
      stub_user_info_api_for(creator)
      allow(SchoolVerificationService).to receive(:new).with(school).and_return(verification_service)

      post verify_admin_school_path(school)
    end

    it 'redirects to school path' do
      expect(response).to redirect_to(admin_school_path(school))
    end

    describe 'when verification was successful' do
      let(:verification_result) { true }

      before do
        follow_redirect!
      end

      it 'displays success message' do
        expect(response.body).to include(I18n.t('administrate.controller.verify_school.success'))
      end
    end

    describe 'when verification was unsuccessful' do
      let(:verification_result) { false }

      before do
        follow_redirect!
      end

      it 'displays failure message' do
        expect(response.body).to include(I18n.t('administrate.controller.verify_school.error'))
      end
    end
  end

  describe 'PUT #reject' do
    let(:creator) { create(:user) }
    let(:school) { create(:school, creator_id: creator.id) }
    let(:rejection_result) { nil }
    let(:verification_service) { instance_double(SchoolVerificationService, reject: rejection_result) }

    before do
      stub_user_info_api_for(creator)
      allow(SchoolVerificationService).to receive(:new).with(school).and_return(verification_service)

      patch reject_admin_school_path(school)
    end

    it 'redirects to school path' do
      expect(response).to redirect_to(admin_school_path(school))
    end

    describe 'when rejection was successful' do
      let(:rejection_result) { true }

      before do
        follow_redirect!
      end

      it 'displays success message' do
        expect(response.body).to include(I18n.t('administrate.controller.reject_school.success'))
      end
    end

    describe 'when rejection was unsuccessful' do
      let(:rejection_result) { false }

      before do
        follow_redirect!
      end

      it 'displays failure message' do
        expect(response.body).to include(I18n.t('administrate.controller.reject_school.error'))
      end
    end
  end

  describe 'PUT #reopen' do
    let(:creator) { create(:user) }
    let(:school) { create(:verified_school, creator_id: creator.id) }
    let(:reopen_result) { nil }
    let(:verification_service) { instance_double(SchoolVerificationService, reopen: reopen_result) }

    before do
      stub_user_info_api_for(creator)
      allow(SchoolVerificationService).to receive(:new).with(school).and_return(verification_service)

      patch reopen_admin_school_path(school)
    end

    it 'redirects to school path' do
      expect(response).to redirect_to(admin_school_path(school))
    end

    describe 'when reopen was successful' do
      let(:reopen_result) { true }

      before do
        follow_redirect!
      end

      it 'displays success message' do
        expect(response.body).to include(I18n.t('administrate.controller.reopen_school.success'))
      end
    end

    describe 'when reopen was unsuccessful' do
      let(:reopen_result) { false }

      before do
        allow(verification_service).to receive(:reopen).and_raise(StandardError)
        follow_redirect!
      end

      it 'displays failure message' do
        expect(response.body).to include(I18n.t('administrate.controller.reopen_school.error'))
      end
    end
  end

  private

  def sign_in_as(user)
    allow(User).to receive(:from_omniauth).and_return(user)
    get '/auth/callback'
  end
end
