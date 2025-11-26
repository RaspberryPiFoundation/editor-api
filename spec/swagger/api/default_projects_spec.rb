require 'swagger_helper'

RSpec.describe 'API::DefaultProjects', type: :request do
  path '/api/default_project' do
    get('show default project') do
      tags 'Default Projects'
      produces 'application/json'
      description 'Get the default project structure'

      response(200, 'successful') do
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

  path '/api/default_project/html' do
    get('show default HTML project') do
      tags 'Default Projects'
      produces 'application/json'
      description 'Get the default HTML project structure'

      response(200, 'successful') do
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

  path '/api/default_project/python' do
    get('show default Python project') do
      tags 'Default Projects'
      produces 'application/json'
      description 'Get the default Python project structure'

      response(200, 'successful') do
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
