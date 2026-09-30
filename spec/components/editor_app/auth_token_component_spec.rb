# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditorApp::AuthTokenComponent, type: :component do
  subject(:rendered) do
    with_controller_class(EditorApp::HomeController) { render_inline(component) }
  end

  around do |example|
    ClimateControl.modify(
      HYDRA_PUBLIC_URL: 'https://auth.example.com',
      EDITOR_HYDRA_CLIENT_ID: 'editor-dev'
    ) { example.run }
  end

  let(:user) { create(:user, token: 'an-access-token') }
  let(:component) { described_class.new(user:, expires_at: 1_800_000_000) }

  def stored_user
    JSON.parse(rendered.css("script##{described_class::ELEMENT_ID}").text)
  end

  it 'hands the editor web component the access token it reads from local storage' do
    expect(stored_user).to include('access_token' => 'an-access-token', 'expires_at' => 1_800_000_000)
  end

  it 'identifies the user so the editor knows which projects are theirs' do
    expect(stored_user['profile']).to include('user' => user.id, 'email' => user.email)
  end

  it 'writes the token under the key the web component is given' do
    expect(rendered.to_html).to include('"oidc.user:https://auth.example.com:editor-dev"')
  end

  it 'tells the page when the token runs out, and where to renew it' do
    element = rendered.css("script##{described_class::ELEMENT_ID}").first
    expect(element.attributes.transform_values(&:value))
      .to include('data-expires-at' => '1800000000', 'data-renewal-url' => '/auth/silent_renew/start')
  end

  context 'when nobody is signed in' do
    let(:component) { described_class.new }

    it 'writes no token' do
      expect(rendered.css("script##{described_class::ELEMENT_ID}")).to be_empty
    end

    it 'clears any token left behind by an earlier session' do
      expect(rendered.to_html).to include('window.localStorage.removeItem(key)')
    end
  end
end
