# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authenticate user' do
  let(:path) { '/admin' }

  context 'when a admin user is logged in' do
    let!(:user) { create(:admin_user) }

    before do
      stub_sign_in(user)
    end

    describe 'Able to access dashboard' do
      it 'remains on the admin path' do
        visit path
        expect(page).to have_current_path(path)
      end
    end
  end

  context 'when a non-admin user is logged in' do
    let!(:factory) { build(:user) }

    before do
      stub_sign_in(factory)
    end

    describe 'Unable to access dashboard' do
      it 'redirects to the root path' do
        visit path
        expect(page).to have_current_path(root_path)
      end

      it 'shows an error message' do
        visit path
        expect(page).to have_text('Not authorized.')
      end
    end
  end
end
