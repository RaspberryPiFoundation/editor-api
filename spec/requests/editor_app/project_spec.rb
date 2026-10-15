# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Code Editor project page' do
  around do |example|
    ClimateControl.modify(
      EDITOR_APP_HOSTS: 'editor.example.com',
      EDITOR_PUBLIC_URL: 'https://classroom.example.com',
      EDITOR_WEB_COMPONENT_URL: 'https://editor-static.example.com/v1.2.3',
      EDITOR_HYDRA_CLIENT_ID: 'editor-test',
      EXPERIENCE_CS_WEB_URL: 'https://experience-cs.example.com'
    ) { example.run }
  end

  let(:starter) { create(:project, user_id: nil, locale: 'en', identifier: 'blank-python-starter') }

  it 'renders a starter project to anybody, with no token needed' do
    get "http://editor.example.com/en/projects/#{starter.identifier}"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<editor-wc')
  end

  it 'loads the editor from the configured web component build' do
    get "http://editor.example.com/en/projects/#{starter.identifier}"
    expect(response.body).to include('https://editor-static.example.com/v1.2.3/web-component.js')
  end

  it 'tells the editor which locale, project and stored token to use' do
    get "http://editor.example.com/en/projects/#{starter.identifier}"
    expect(response.body).to include('identifier="blank-python-starter"')
      .and include('locale="en"')
      .and include('auth_key="oidc.user:http://localhost:9001:editor-test"')
  end

  it 'spells out the features it does not have, which the editor reads as opt-outs' do
    get "http://editor.example.com/en/projects/#{starter.identifier}"
    expect(response.body).to include('offline_enabled="false"')
      .and include('friendly_errors_enabled="false"')
  end

  it 'takes friendly errors from the feature flag rather than an API call' do
    Flipper.enable(:friendly_errors)
    get "http://editor.example.com/en/projects/#{starter.identifier}"
    expect(response.body).to include('friendly_errors_enabled="true"')
  end

  it 'gives the editor the whole viewport by dropping the footer' do
    get "http://editor.example.com/en/projects/#{starter.identifier}"
    expect(response.body).not_to include('<footer class="footer">')
  end

  it 'falls back to the English project when the locale has no translation' do
    get "http://editor.example.com/fr-FR/projects/#{starter.identifier}"
    expect(response).to have_http_status(:ok)
  end

  it 'reports an unknown project as missing' do
    get 'http://editor.example.com/en/projects/nope-nope-nope'
    expect(response).to have_http_status(:not_found)
    expect(response.body).to include('This page does not exist')
  end

  it 'hands Scratch projects back to Experience CS' do
    scratch = create(:project, user_id: nil, locale: 'en', project_type: Project::Types::SCRATCH)
    get "http://editor.example.com/en/projects/#{scratch.identifier}"
    expect(response).to redirect_to("https://experience-cs.example.com/projects/#{scratch.identifier}")
  end

  context "with somebody else's project" do
    let(:project) { create(:project, locale: nil) }

    it 'refuses access rather than showing the editor' do
      get "http://editor.example.com/en/projects/#{project.identifier}"
      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include('You cannot access this page')
    end

    it 'offers a way to log in, in case it is their own project' do
      get "http://editor.example.com/en/projects/#{project.identifier}"
      expect(response.body).to include(CGI.escapeHTML("/auth/rpi?returnTo=%2Fen%2Fprojects%2F#{project.identifier}"))
    end
  end

  context 'when nobody is signed in' do
    it 'gives the editor a form to submit when it asks for a login' do
      get "http://editor.example.com/en/projects/#{starter.identifier}"
      expect(response.body).to include('id="editor-app-project-login"')
    end
  end

  context 'when the project owner is signed in' do
    let(:user) { create(:user) }
    let(:project) { create(:project, user_id: user.id, locale: nil) }

    before { stub_sign_in(user) }

    it 'renders their project' do
      get "http://editor.example.com/en/projects/#{project.identifier}"
      expect(response).to have_http_status(:ok)
    end

    it 'has no login form to submit, being signed in already' do
      get "http://editor.example.com/en/projects/#{project.identifier}"
      expect(response.body).not_to include('id="editor-app-project-login"')
    end
  end

  context 'when the web component URL names the latest version' do
    around do |example|
      ClimateControl.modify(EDITOR_WEB_COMPONENT_URL: 'https://editor-static.example.com/latest_version') do
        example.run
      end
    end

    before { Rails.cache.clear }

    it 'follows the indirection to the current release' do
      stub_request(:get, 'https://editor-static.example.com/latest_version').to_return(body: "release/v4.5.6\n")
      get "http://editor.example.com/en/projects/#{starter.identifier}"
      expect(response.body).to include('https://editor-static.example.com/release/v4.5.6/web-component.js')
    end
  end
end
