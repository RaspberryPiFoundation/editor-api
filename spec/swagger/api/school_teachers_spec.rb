require 'swagger_helper'

RSpec.describe 'API::SchoolTeachers', type: :request do
  path '/api/schools/{school_id}/teachers' do
    parameter name: :school_id, in: :path, type: :string, description: 'School ID'

    get('list school teachers') do
      tags 'School Teachers'
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

    post('add school teacher') do
      tags 'School Teachers'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :teacher, in: :body, schema: {
        type: :object,
        properties: {
          email_address: { type: :string, format: :email }
        },
        required: ['email_address']
      }

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_id) { school.id }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:teacher) { { email_address: 'teacher@example.com' } }

        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_id) { school.id }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:teacher) { { email_address: 'invalid-email' } }

        run_test!
      end
    end
  end
end
