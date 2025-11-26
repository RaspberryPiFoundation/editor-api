require 'swagger_helper'

RSpec.describe 'API::Projects::Remixes', type: :request do
  path '/api/projects/{project_id}/remixes' do
    parameter name: :project_id, in: :path, type: :string, description: 'Project identifier'

    get('list project remixes') do
      tags 'Project Remixes'
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
  end

  path '/api/projects/{project_id}/remix' do
    parameter name: :project_id, in: :path, type: :string, description: 'Project identifier'

    get('show current user remix') do
      tags 'Project Remixes'
      produces 'application/json'
      security [bearer_auth: []]

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:original_project) { create(:project) }
        let(:remix) { create(:project, user: user, remixed_from: original_project) }
        let(:project_id) { original_project.identifier }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end

      response(404, 'not found') do
        let(:user) { create(:user) }
        let(:project) { create(:project) }
        let(:project_id) { project.identifier }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end

    post('create remix') do
      tags 'Project Remixes'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :remix, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          locale: { type: :string }
        }
      }

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:project) { create(:project) }
        let(:project_id) { project.identifier }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:remix) { { name: 'My Remix' } }

        run_test!
      end
    end
  end

  path '/api/projects/{project_id}/remix/identifier' do
    parameter name: :project_id, in: :path, type: :string, description: 'Project identifier'

    get('get remix identifier') do
      tags 'Project Remixes'
      produces 'application/json'
      security [bearer_auth: []]

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:original_project) { create(:project) }
        let(:remix) { create(:project, user: user, remixed_from: original_project) }
        let(:project_id) { original_project.identifier }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end
  end
end
