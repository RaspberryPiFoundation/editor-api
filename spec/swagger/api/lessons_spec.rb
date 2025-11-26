require 'swagger_helper'

RSpec.describe 'API::Lessons', type: :request do
  path '/api/lessons' do
    parameter name: :school_class_id, in: :query, type: :string, required: false, description: 'Filter by school class ID'
    parameter name: :include_archived, in: :query, type: :boolean, required: false, description: 'Include archived lessons'

    get('list lessons') do
      tags 'Lessons'
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

    post('create lesson') do
      tags 'Lessons'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :lesson, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          visibility: { type: :string, enum: %w[private teachers students] },
          school_class_id: { type: :string },
          project_id: { type: :string }
        },
        required: %w[name visibility school_class_id project_id]
      }

      response(201, 'created') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_class) { create(:school_class, school: school) }
        let(:project) { create(:project, user: user) }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:lesson) do
          {
            name: 'Test Lesson',
            visibility: 'students',
            school_class_id: school_class.id,
            project_id: project.id
          }
        end

        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:user) { create(:user) }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:lesson) { { name: '' } }

        run_test!
      end
    end
  end

  path '/api/lessons/{id}' do
    parameter name: :id, in: :path, type: :string, description: 'Lesson ID'

    get('show lesson') do
      tags 'Lessons'
      produces 'application/json'
      security [bearer_auth: []]

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_class) { create(:school_class, school: school) }
        let(:project) { create(:project, user: user) }
        let(:lesson) { create(:lesson, school_class: school_class, project: project) }
        let(:id) { lesson.id }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end

    patch('update lesson') do
      tags 'Lessons'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :lesson, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          visibility: { type: :string, enum: %w[private teachers students] }
        }
      }

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_class) { create(:school_class, school: school) }
        let(:project) { create(:project, user: user) }
        let(:lesson_record) { create(:lesson, school_class: school_class, project: project) }
        let(:id) { lesson_record.id }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:lesson) { { name: 'Updated Lesson' } }

        run_test!
      end
    end

    delete('archive lesson') do
      tags 'Lessons'
      security [bearer_auth: []]

      parameter name: :undo, in: :query, type: :boolean, required: false, description: 'Set to true to unarchive'

      response(204, 'no content') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_class) { create(:school_class, school: school) }
        let(:project) { create(:project, user: user) }
        let(:lesson) { create(:lesson, school_class: school_class, project: project) }
        let(:id) { lesson.id }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end
  end

  path '/api/lessons/{id}/copy' do
    parameter name: :id, in: :path, type: :string, description: 'Lesson ID'

    post('copy lesson') do
      tags 'Lessons'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :lesson, in: :body, schema: {
        type: :object,
        properties: {
          school_class_id: { type: :string }
        },
        required: ['school_class_id']
      }

      response(201, 'created') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_class) { create(:school_class, school: school) }
        let(:target_class) { create(:school_class, school: school) }
        let(:project) { create(:project, user: user) }
        let(:lesson_record) { create(:lesson, school_class: school_class, project: project) }
        let(:id) { lesson_record.id }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:lesson) { { school_class_id: target_class.id } }

        run_test!
      end
    end
  end
end
