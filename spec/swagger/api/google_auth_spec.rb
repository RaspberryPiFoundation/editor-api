require 'swagger_helper'

RSpec.describe 'API::GoogleAuth', type: :request do
  path '/api/google/auth/exchange-code' do
    post('exchange Google OAuth code for tokens') do
      tags 'Google Auth'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]
      description 'Exchange a Google OAuth authorization code for access and refresh tokens'

      parameter name: :auth, in: :body, schema: {
        type: :object,
        properties: {
          code: { type: :string, description: 'Google OAuth authorization code' }
        },
        required: ['code']
      }

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:auth) { { code: 'google-auth-code' } }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:auth) { { code: '' } }

        run_test!
      end
    end
  end
end
