require 'swagger_helper'

RSpec.describe 'API::Feedback', type: :request do
  path '/api/projects/{project_id}/feedback' do
    parameter name: :project_id, in: :path, type: :string, description: 'Project identifier'

    get('list project feedback') do
      tags 'Project Feedback'
      produces 'application/json'
      security [bearer_auth: []]

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let(:project_id) { project.identifier }
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

    post('create project feedback') do
      tags 'Project Feedback'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :feedback, in: :body, schema: {
        type: :object,
        properties: {
          comment: { type: :string }
        },
        required: ['comment']
      }

      response(201, 'created') do
        let(:user) { create(:user) }
        let(:project) { create(:project) }
        let(:project_id) { project.identifier }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:feedback) { { comment: 'Great work!' } }

        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:user) { create(:user) }
        let(:project) { create(:project) }
        let(:project_id) { project.identifier }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:feedback) { { comment: '' } }

        run_test!
      end
    end
  end

  path '/api/projects/{project_id}/feedback/{id}/read' do
    parameter name: :project_id, in: :path, type: :string, description: 'Project identifier'
    parameter name: :id, in: :path, type: :string, description: 'Feedback ID'

    put('mark feedback as read') do
      tags 'Project Feedback'
      security [bearer_auth: []]

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let(:feedback_item) { create(:feedback, project: project) }
        let(:project_id) { project.identifier }
        let(:id) { feedback_item.id }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end
  end
end
