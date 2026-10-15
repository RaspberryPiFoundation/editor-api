# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditorApp::GlobalNavComponent, type: :component do
  subject(:rendered) do
    with_controller_class(EditorApp::HomeController) { render_inline(component) }
  end

  let(:component) { described_class.new(current_path: '/en/projects', signed_in: false) }

  it 'tells the nav which locale the page is in' do
    expect(rendered.css('rpf-global-nav').attr('locale').value).to eq('en')
  end

  it 'offers each selectable language at the equivalent path in that language' do
    locales = JSON.parse(rendered.css('rpf-global-nav').attr('locales').value)

    expect(locales).to include(
      'fr-FR' => { 'url' => '/fr-FR/projects', 'text' => 'Français' },
      'en-US' => { 'url' => '/en-US/projects', 'text' => 'English (US)' }
    )
  end

  it 'keeps the return path so logging in comes back to the current page' do
    expect(rendered.css('rpf-global-nav').attr('log-in-path').value)
      .to eq('/auth/rpi?returnTo=%2Fen%2Fprojects')
  end

  it 'asks for a fresh account when signing up' do
    expect(rendered.css('rpf-global-nav').attr('sign-up-path').value)
      .to include('login_options=force_signup')
  end

  it 'gives the nav a token its forms can post with' do
    expect(rendered.css('rpf-global-nav').attr('log-in-token').value).to be_present
  end

  context 'when the path has no locale prefix' do
    let(:component) { described_class.new(current_path: '/', signed_in: false) }

    it 'points each language at its own root' do
      locales = JSON.parse(rendered.css('rpf-global-nav').attr('locales').value)

      expect(locales['es-LA']['url']).to eq('/es-LA')
    end
  end

  context 'when a school student is signed in' do
    let(:component) { described_class.new(current_path: '/en', signed_in: true, student: true) }

    it 'hides the account dropdown, which students cannot use' do
      expect(rendered.css('rpf-global-nav').attr('hide-account-dropdown')).to be_present
    end
  end

  context 'when a full account is signed in' do
    let(:component) { described_class.new(current_path: '/en', signed_in: true) }

    it 'leaves the account dropdown in place' do
      expect(rendered.css('rpf-global-nav').attr('hide-account-dropdown')).to be_nil
    end
  end
end
