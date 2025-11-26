require 'swagger_helper'

RSpec.describe 'API::SchoolStudents', type: :request do
  path '/api/schools/{school_id}/students' do
    parameter name: :school_id, in: :path, type: :string, description: 'School ID'

    get('list school students') do
      tags 'School Students'
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

    post('create school student') do
      tags 'School Students'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :student, in: :body, schema: {
        type: :object,
        properties: {
          username: { type: :string },
          name: { type: :string },
          password: { type: :string }
        },
        required: %w[username name password]
      }

      response(204, 'no content') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_id) { school.id }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:student) do
          {
            username: 'student1',
            name: 'Test Student',
            password: 'password123'
          }
        end

        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_id) { school.id }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:student) { { username: '' } }

        run_test!
      end
    end
  end

  path '/api/schools/{school_id}/students/batch' do
    parameter name: :school_id, in: :path, type: :string, description: 'School ID'

    post('batch create school students') do
      tags 'School Students'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :students, in: :body, schema: {
        type: :object,
        properties: {
          students: {
            type: :array,
            items: {
              type: :object,
              properties: {
                username: { type: :string },
                name: { type: :string },
                password: { type: :string }
              },
              required: %w[username name password]
            }
          }
        }
      }

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_id) { school.id }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:students) do
          {
            students: [
              { username: 'student1', name: 'Student 1', password: 'pass1' },
              { username: 'student2', name: 'Student 2', password: 'pass2' }
            ]
          }
        end

        run_test!
      end
    end
  end

  path '/api/schools/{school_id}/students/{id}' do
    parameter name: :school_id, in: :path, type: :string, description: 'School ID'
    parameter name: :id, in: :path, type: :string, description: 'Student ID'

    patch('update school student') do
      tags 'School Students'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :student, in: :body, schema: {
        type: :object,
        properties: {
          username: { type: :string },
          name: { type: :string },
          password: { type: :string }
        }
      }

      response(204, 'no content') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_id) { school.id }
        let(:id) { 'student-id' }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:student) { { name: 'Updated Name' } }

        run_test!
      end
    end

    delete('delete school student') do
      tags 'School Students'
      security [bearer_auth: []]

      response(204, 'no content') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_id) { school.id }
        let(:id) { 'student-id' }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end
  end
end
