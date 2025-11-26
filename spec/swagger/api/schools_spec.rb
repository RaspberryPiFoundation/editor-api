require 'swagger_helper'

RSpec.describe 'API::Schools', type: :request do
  path '/api/schools' do
    get('list schools') do
      tags 'Schools'
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

    post('create school') do
      tags 'Schools'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :school, in: :body, schema: {
        type: :object,
        properties: {
          school: {
            type: :object,
            properties: {
              name: { type: :string },
              website: { type: :string },
              reference: { type: :string },
              country_code: { type: :string },
              address_line_1: { type: :string },
              address_line_2: { type: :string },
              municipality: { type: :string },
              administrative_area: { type: :string },
              postal_code: { type: :string },
              creator_role: { type: :string },
              creator_department: { type: :string },
              creator_agree_authority: { type: :boolean },
              creator_agree_terms_and_conditions: { type: :boolean },
              creator_agree_to_ux_contact: { type: :boolean },
              creator_agree_responsible_safeguarding: { type: :boolean }
            },
            required: %w[name country_code]
          }
        }
      }

      response(201, 'created') do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:school) { { school: { name: 'Test School', country_code: 'GB' } } }

        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:school) { { school: { name: '' } } }

        run_test!
      end
    end
  end

  path '/api/schools/{id}' do
    parameter name: :id, in: :path, type: :string, description: 'School ID'

    get('show school') do
      tags 'Schools'
      produces 'application/json'
      security [bearer_auth: []]

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:id) { school.id }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end

    patch('update school') do
      tags 'Schools'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :school, in: :body, schema: {
        type: :object,
        properties: {
          school: {
            type: :object,
            properties: {
              name: { type: :string },
              website: { type: :string }
            }
          }
        }
      }

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:school_record) { create(:school, creator: user) }
        let(:id) { school_record.id }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:school) { { school: { name: 'Updated School' } } }

        run_test!
      end
    end

    delete('delete school') do
      tags 'Schools'
      security [bearer_auth: []]

      response(204, 'no content') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:id) { school.id }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end
  end
end
