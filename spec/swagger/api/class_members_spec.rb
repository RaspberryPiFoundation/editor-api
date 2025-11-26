require 'swagger_helper'

RSpec.describe 'API::ClassMembers', type: :request do
  path '/api/schools/{school_id}/classes/{class_id}/members' do
    parameter name: :school_id, in: :path, type: :string, description: 'School ID'
    parameter name: :class_id, in: :path, type: :string, description: 'Class ID'

    get('list class members') do
      tags 'Class Members'
      produces 'application/json'
      security [bearer_auth: []]

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_class) { create(:school_class, school: school) }
        let(:school_id) { school.id }
        let(:class_id) { school_class.id }
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

    post('add class member') do
      tags 'Class Members'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :member, in: :body, schema: {
        type: :object,
        properties: {
          student_id: { type: :string }
        },
        required: ['student_id']
      }

      response(204, 'no content') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_class) { create(:school_class, school: school) }
        let(:school_id) { school.id }
        let(:class_id) { school_class.id }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:member) { { student_id: 'student-uuid' } }

        run_test!
      end
    end
  end

  path '/api/schools/{school_id}/classes/{class_id}/members/batch' do
    parameter name: :school_id, in: :path, type: :string, description: 'School ID'
    parameter name: :class_id, in: :path, type: :string, description: 'Class ID'

    post('batch add class members') do
      tags 'Class Members'
      consumes 'application/json'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :members, in: :body, schema: {
        type: :object,
        properties: {
          student_ids: {
            type: :array,
            items: { type: :string }
          }
        }
      }

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_class) { create(:school_class, school: school) }
        let(:school_id) { school.id }
        let(:class_id) { school_class.id }
        let(:Authorization) { "Bearer #{user.token}" }
        let(:members) { { student_ids: %w[student-1 student-2] } }

        run_test!
      end
    end
  end

  path '/api/schools/{school_id}/classes/{class_id}/members/{id}' do
    parameter name: :school_id, in: :path, type: :string, description: 'School ID'
    parameter name: :class_id, in: :path, type: :string, description: 'Class ID'
    parameter name: :id, in: :path, type: :string, description: 'Member ID'

    delete('remove class member') do
      tags 'Class Members'
      security [bearer_auth: []]

      response(204, 'no content') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:school_class) { create(:school_class, school: school) }
        let(:school_id) { school.id }
        let(:class_id) { school_class.id }
        let(:id) { 'member-id' }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end
  end
end
