require 'swagger_helper'

RSpec.describe 'API::SchoolMembers', type: :request do
  path '/api/schools/{school_id}/members' do
    parameter name: :school_id, in: :path, type: :string, description: 'School ID'

    get('list school members') do
      tags 'School Members'
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
