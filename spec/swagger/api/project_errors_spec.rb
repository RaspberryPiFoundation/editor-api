require 'swagger_helper'

RSpec.describe 'API::ProjectErrors', type: :request do
  path '/api/project_errors' do
    post('report project error') do
      tags 'Project Errors'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]
      description 'Report an error that occurred in a project'

      parameter name: :error, in: :body, schema: {
        type: :object,
        properties: {
          project_id: { type: :string },
          error_type: { type: :string },
          message: { type: :string },
          stack_trace: { type: :string }
        },
        required: %w[error_type message]
      }

      response(201, 'created') do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:error) do
          {
            error_type: 'RuntimeError',
            message: 'Something went wrong'
          }
        end

        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:error) { { error_type: '' } }

        run_test!
      end
    end
  end
end
