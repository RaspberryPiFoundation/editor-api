# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Code Editor home page' do
  around do |example|
    ClimateControl.modify(
      EDITOR_APP_HOSTS: 'editor.example.com',
      EDITOR_PUBLIC_URL: 'https://classroom.example.com'
    ) { example.run }
  end

  it 'responds 200 OK' do
    get 'http://editor.example.com/en'
    expect(response).to have_http_status(:ok)
  end

  it 'renders the global navigation' do
    get 'http://editor.example.com/en'
    expect(response.body).to include('<rpf-global-nav').and include('rpf-global-nav.esm.js')
  end

  it 'renders the secondary navigation' do
    get 'http://editor.example.com/en'
    expect(response.body).to include('secondary-nav__title')
  end

  it 'renders the footer with the feedback link' do
    get 'http://editor.example.com/en'
    expect(response.body).to include('<footer class="footer">')
      .and include(EditorApp::FooterComponent::FEEDBACK_URL)
  end

  it 'offers a starter project for each language' do
    get 'http://editor.example.com/en'
    expect(response.body).to include('/en/projects/blank-python-starter')
      .and include('/en/projects/blank-html-starter')
  end

  it 'renders the page in the locale from the path' do
    get 'http://editor.example.com/fr-FR'
    expect(response.body).to include('Commencer à coder, aucune configuration requise!')
      .and include('<html lang="fr-FR">')
  end

  it 'links to the Projects site in the equivalent locale' do
    get 'http://editor.example.com/en-US'
    expect(response.body).to include('https://projects.raspberrypi.org/en/pathways/python-intro')
  end

  context 'when nobody is signed in' do
    it 'offers a way to log in to the Code Editor' do
      get 'http://editor.example.com/en'
      expect(response.body).to include('Log in to Code Editor')
    end

    it 'sends the Code Editor login to the project index after authenticating' do
      get 'http://editor.example.com/en'
      expect(response.body).to include(CGI.escapeHTML('/auth/rpi?returnTo=%2Fen%2Fprojects'))
    end

    it 'has nothing to renew' do
      get 'http://editor.example.com/en'
      expect(response.body).not_to include('editor_app/session_renewal')
    end

    it 'offers the Code Classroom logins' do
      get 'http://editor.example.com/en'
      expect(response.body).to include('https://classroom.example.com/auth/user_login/student')
        .and include('https://classroom.example.com/auth/user_login/full')
    end
  end

  context 'when a user is signed in' do
    before { stub_sign_in(create(:user)) }

    it 'does not offer the login options' do
      get 'http://editor.example.com/en'
      expect(response.body).not_to include('Log in to Code Editor')
    end

    it 'still offers the starter projects' do
      get 'http://editor.example.com/en'
      expect(response.body).to include('/en/projects/blank-python-starter')
    end

    it 'keeps their access token fresh without navigating away from the page' do
      get 'http://editor.example.com/en'
      expect(response.body).to include('editor_app/session_renewal')
        .and include('Log in again')
    end
  end

  context 'when a school student is signed in' do
    before { stub_sign_in(create(:student)) }

    it 'sends them to Code Classroom rather than offering starter projects' do
      get 'http://editor.example.com/en'
      expect(response.body).to include('https://classroom.example.com/en/school')
        .and not_include('/en/projects/blank-python-starter')
    end
  end
end
