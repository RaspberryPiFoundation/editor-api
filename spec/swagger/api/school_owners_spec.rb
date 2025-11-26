require 'swagger_helper'

RSpec.describe 'API::SchoolOwners', type: :request do
  path '/api/schools/{school_id}/owners' do
    parameter name: :school_id, in: :path, type: :string, description: 'School ID'

    get('list school owners') do
      tags 'School Owners'
      produces 'application/json'
      security [bearer_auth: []]

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_id) { school.id }
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
    end
  end
end
