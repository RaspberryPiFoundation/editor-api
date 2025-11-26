require 'swagger_helper'

RSpec.describe 'API::TeacherInvitations', type: :request do
  path '/api/teacher_invitations/{token}' do
    parameter name: :token, in: :path, type: :string, description: 'Invitation token'

    get('show teacher invitation') do
      tags 'Teacher Invitations'
      produces 'application/json'
      security [bearer_auth: []]

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:invitation) { create(:teacher_invitation, school: school) }
        let(:token) { invitation.token }
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

      response(404, 'not found') do
        let(:user) { create(:user) }
        let(:token) { 'invalid-token' }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end
  end

  path '/api/teacher_invitations/{token}/accept' do
    parameter name: :token, in: :path, type: :string, description: 'Invitation token'

    put('accept teacher invitation') do
      tags 'Teacher Invitations'
      produces 'application/json'
      security [bearer_auth: []]

      response(200, 'successful') do
        let(:user) { create(:user) }
        let(:school) { create(:school, creator: user) }
        let(:invitation) { create(:teacher_invitation, school: school) }
        let(:token) { invitation.token }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:user) { create(:user) }
        let(:token) { 'invalid-token' }
        let(:Authorization) { "Bearer #{user.token}" }

        run_test!
      end
    end
  end
end
