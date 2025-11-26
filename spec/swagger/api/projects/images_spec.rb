require 'swagger_helper'

RSpec.describe 'API::Projects::Images', type: :request do
  path '/api/projects/{project_id}/images' do
    parameter name: :project_id, in: :path, type: :string, description: 'Project identifier'

    get('list project images') do
      tags 'Project Images'
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

    post('upload project images') do
      tags 'Project Images'
      consumes 'multipart/form-data'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :images, in: :formData, type: :array, items: { type: :string, format: :binary }, description: 'Image files to upload'

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:project) { create(:project, user: user) }
        let(:project_id) { project.identifier }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end
  end
end
