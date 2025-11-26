require 'swagger_helper'

RSpec.describe 'api/projects', type: :request do
  path '/api/projects/{identifier}' do
    parameter name: :identifier, in: :path, type: :string, description: 'Project identifier'
    parameter name: :locale, in: :query, type: :string, required: false, description: 'Project locale'

    get('show project') do
      tags 'Projects'
      produces 'application/json'
      security [bearer_auth: []]

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:project) { create(:project, identifier: 'test-project', user: user) }
        let(:identifier) { project.identifier }
        let(:Authorization) { 'Bearer valid-token' }

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
        let(:Authorization) { 'Bearer valid-token' }
        let(:identifier) { 'nonexistent' }
        run_test!
      end
    end

    patch('update project') do
      tags 'Projects'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :project, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          locale: { type: :string },
          components: {
            type: :array,
            items: {
              type: :object,
              properties: {
                id: { type: :string },
                name: { type: :string },
                extension: { type: :string },
                content: { type: :string }
              }
            }
          }
        }
      }

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:project) { create(:project, identifier: 'test-project', user: user) }
        let(:identifier) { project.identifier }
        let(:Authorization) { 'Bearer valid-token' }
        let(:project) { { name: 'Updated Project' } }

        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:user) { create(:user) }
        let(:project) { create(:project, identifier: 'test-project', user: user) }
        let(:identifier) { project.identifier }
        let(:Authorization) { 'Bearer valid-token' }
        let(:project) { { name: '' } }

        run_test!
      end
    end

    delete('delete project') do
      tags 'Projects'
      security [bearer_auth: []]

      response(204, 'no content') do
        let(:user) { create(:user) }
        let(:project) { create(:project, identifier: 'test-project', user: user) }
        let(:identifier) { project.identifier }
        let(:Authorization) { 'Bearer valid-token' }

        run_test!
      end
    end
  end

  path '/api/projects' do
    parameter name: :user_id, in: :query, type: :string, format: :uuid, required: false, description: 'Filter by user ID'
    parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number for pagination'
    parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'

    get('list projects') do
      tags 'Projects'
      produces 'application/json'
      security [bearer_auth: []]

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

    post('create project') do
      tags 'Projects'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :project, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          identifier: { type: :string },
          locale: { type: :string },
          school_id: { type: :string },
          lesson_id: { type: :string },
          components: {
            type: :array,
            items: {
              type: :object,
              properties: {
                name: { type: :string },
                extension: { type: :string },
                content: { type: :string },
                default: { type: :boolean }
              }
            }
          }
        },
        required: ['name']
      }

      response(201, 'created') do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:project) { { name: 'My Project', identifier: 'my-proj' } }

        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:project) { { name: '' } }

        run_test!
      end
    end
  end

  path '/api/projects/{id}/context' do
    parameter name: :id, in: :path, type: :string, description: 'Project identifier'

    get('show project context') do
      tags 'Projects'
      produces 'application/json'
      security [bearer_auth: []]
      description 'Get additional context about a project (e.g., lesson, class info)'

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:project) { create(:project, identifier: 'test-project', user: user) }
        let(:id) { project.identifier }
        let(:Authorization) { 'Bearer valid-token' }

        run_test!
      end
    end
  end
end
