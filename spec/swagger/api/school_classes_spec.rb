require 'swagger_helper'

RSpec.describe 'API::SchoolClasses', type: :request do
  path '/api/schools/{school_id}/classes' do
    parameter name: :school_id, in: :path, type: :string, description: 'School ID'

    get('list school classes') do
      tags 'School Classes'
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

    post('create school class') do
      tags 'School Classes'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :school_class, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string }
        },
        required: ['name']
      }

      response(201, 'created') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_id) { school.id }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:school_class) { { name: 'Test Class' } }

        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_id) { school.id }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:school_class) { { name: '' } }

        run_test!
      end
    end
  end

  path '/api/schools/{school_id}/classes/import' do
    parameter name: :school_id, in: :path, type: :string, description: 'School ID'

    post('import school classes from Google Classroom') do
      tags 'School Classes'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :classes, in: :body, schema: {
        type: :object,
        properties: {
          classes: {
            type: :array,
            items: {
              type: :object,
              properties: {
                external_id: { type: :string },
                name: { type: :string }
              }
            }
          }
        }
      }

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_id) { school.id }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:classes) { { classes: [{ external_id: '123', name: 'Imported Class' }] } }

        run_test!
      end
    end
  end

  path '/api/schools/{school_id}/classes/{id}' do
    parameter name: :school_id, in: :path, type: :string, description: 'School ID'
    parameter name: :id, in: :path, type: :string, description: 'Class ID'

    get('show school class') do
      tags 'School Classes'
      produces 'application/json'
      security [bearer_auth: []]

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_class) { create(:school_class, school: school) }
        let(:school_id) { school.id }
        let(:id) { school_class.id }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end

    patch('update school class') do
      tags 'School Classes'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :school_class, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string }
        }
      }

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_class) { create(:school_class, school: school) }
        let(:school_id) { school.id }
        let(:id) { school_class.id }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:school_class) { { name: 'Updated Class' } }

        run_test!
      end
    end

    delete('delete school class') do
      tags 'School Classes'
      security [bearer_auth: []]

      response(204, 'no content') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_class) { create(:school_class, school: school) }
        let(:school_id) { school.id }
        let(:id) { school_class.id }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end
  end
end
