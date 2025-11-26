require 'swagger_helper'

RSpec.describe 'API::SchoolProjects', type: :request do
  path '/api/projects/{id}/finished' do
    parameter name: :id, in: :path, type: :string, description: 'Project identifier'

    get('show project finished status') do
      tags 'School Projects'
      produces 'application/json'
      security [bearer_auth: []]
      description 'Get the finished status for a school project'

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let(:id) { project.identifier }
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

    put('set project finished status') do
      tags 'School Projects'
      consumes 'application/json'
      security [bearer_auth: []]

      parameter name: :finished, in: :body, schema: {
        type: :object,
        properties: {
          finished: { type: :boolean }
        }
      }

      response(204, 'no content') do
        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let(:id) { project.identifier }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:finished) { { finished: true } }

        run_test!
      end
    end
  end

  path '/api/projects/{id}/status' do
    parameter name: :id, in: :path, type: :string, description: 'Project identifier'

    get('show project status') do
      tags 'School Projects'
      produces 'application/json'
      security [bearer_auth: []]
      description 'Get the submission status for a school project'

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let(:id) { project.identifier }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end
  end

  path '/api/projects/{id}/submit' do
    parameter name: :id, in: :path, type: :string, description: 'Project identifier'

    post('submit project') do
      tags 'School Projects'
      security [bearer_auth: []]
      description 'Submit a school project for review'

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let(:id) { project.identifier }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end
  end

  path '/api/projects/{id}/unsubmit' do
    parameter name: :id, in: :path, type: :string, description: 'Project identifier'

    post('unsubmit project') do
      tags 'School Projects'
      security [bearer_auth: []]
      description 'Unsubmit a previously submitted school project'

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let(:id) { project.identifier }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end
  end

  path '/api/projects/{id}/return' do
    parameter name: :id, in: :path, type: :string, description: 'Project identifier'

    post('return project to student') do
      tags 'School Projects'
      security [bearer_auth: []]
      description 'Teacher returns a submitted project to the student for revisions'

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:project) { create(:project) }
        let(:id) { project.identifier }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end
  end

  path '/api/projects/{id}/complete' do
    parameter name: :id, in: :path, type: :string, description: 'Project identifier'

    post('mark project as complete') do
      tags 'School Projects'
      security [bearer_auth: []]
      description 'Teacher marks a submitted project as complete'

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:project) { create(:project) }
        let(:id) { project.identifier }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end
  end
end
