# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'EditorApp engine mounting' do
  around do |example|
    ClimateControl.modify(EDITOR_APP_HOSTS: 'editor.example.com') { example.run }
  end

  it 'redirects the root of an editor host to the default locale' do
    get 'http://editor.example.com/'
    expect(response).to redirect_to('http://editor.example.com/en')
  end

  it 'honours the i18next cookie when choosing the locale to redirect to' do
    get 'http://editor.example.com/', headers: { 'HTTP_COOKIE' => 'i18next=fr-FR' }
    expect(response).to redirect_to('http://editor.example.com/fr-FR')
  end

  it 'leaves the root of a non-editor host to the host application' do
    get 'http://editor-api.example.com/'
    expect(response.body).to include('Log in')
  end

  it 'keeps serving the API on an editor host' do
    get 'http://editor.example.com/info/release'
    expect(response).to have_http_status(:ok)
  end
end
