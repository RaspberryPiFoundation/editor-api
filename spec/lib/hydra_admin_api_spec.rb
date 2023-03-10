# frozen_string_literal: true

require 'rails_helper'
require 'hydra_admin_api'

RSpec.describe HydraAdminApi do
  let(:hydra_admin_url) { 'https://hydra.com/admin' }
  let(:hydra_admin_api_key) { 'secret' }

  before do
    stub_const('HydraAdminApi::ADMIN_URL', hydra_admin_url)
    stub_const('HydraAdminApi::ADMIN_API_KEY', hydra_admin_api_key)
  end

  describe '#fetch_oauth_user_id' do
    subject(:response) { described_class.fetch_oauth_user_id(**args) }

    let(:args) { { token: 'abc123' } }
    let(:uuid) { SecureRandom.uuid }
    let(:stubbed_response) { { active: true, sub: uuid } }
    # `active` is a required field in the response; `sub` is the "subject".
    #
    # See https://www.ory.sh/docs/reference/api#tag/oAuth2/operation/introspectOAuth2Token

    before do
      stub_request(:post, "#{hydra_admin_url}/oauth2/introspect")
        .with(body: args, headers: { apiKey: hydra_admin_api_key })
        .to_return(status: 200,
                   body: stubbed_response.to_json,
                   headers: { content_type: 'application/json' })
    end

    it { is_expected.to eq uuid }

    context 'when the token is not found' do
      let(:stubbed_response) { { active: false } }

      it { is_expected.to be_nil }
    end

    context 'when a token is not set' do
      let(:args) { { token: nil } }

      it { is_expected.to be_nil }
    end

    context 'when BYPASS_AUTH is set' do
      before do
        stub_const('HydraAdminApi::BYPASS_AUTH', 'yes')
      end

      # Default bypass ID from
      # https://github.com/RaspberryPiFoundation/rpi-auth/blob/main/lib/rpi_auth/engine.rb#L17
      it { is_expected.to eq 'b6301f34-b970-4d4f-8314-f877bad8b150' }

      context 'when BYPASS_AUTH_USER_ID is set' do
        let(:bypass_auth_user_id) { 'some-user-id-here' }

        before do
          stub_const('HydraAdminApi::BYPASS_AUTH_USER_ID', bypass_auth_user_id)
        end

        it { is_expected.to eq bypass_auth_user_id }
      end
    end
  end
end
