require 'swagger_helper'

RSpec.describe 'API::MySchool', type: :request do
  path '/api/school' do
    get('show current user school') do
      tags 'My School'
      produces 'application/json'
      security [bearer_auth: []]
      description 'Returns the school associated with the current user'

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:Authorization) { "Bearer #{user.token}" }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end

      response(404, 'not found') do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end
  end
end
