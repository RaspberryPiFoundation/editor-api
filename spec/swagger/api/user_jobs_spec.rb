require 'swagger_helper'

RSpec.describe 'API::UserJobs', type: :request do
  path '/api/user_jobs' do
    get('list user jobs') do
      tags 'User Jobs'
      produces 'application/json'
      security [bearer_auth: []]
      description 'Get background jobs for the current user'

      response(200, 'successful') do
        let(:user) { create(:user) }
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

  path '/api/user_jobs/{id}' do
    parameter name: :id, in: :path, type: :string, description: 'Job ID'

    get('show user job') do
      tags 'User Jobs'
      produces 'application/json'
      security [bearer_auth: []]
      description 'Get status of a specific background job'

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:id) { 'job-uuid' }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end

      response(404, 'not found') do
        let(:user) { create(:user) }
        let(:id) { 'invalid-uuid' }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end
  end
end
