# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Join endpoint' do
  let(:school) { create(:school, code: '12-34-56') }
  let(:school_class) { create(:school_class, school:, join_code: 'B123-C456') }
  let(:student) { create(:user, email: 'student@example.edu') }
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }

  before do
    SchoolEmailDomain.create!(school:, domain: 'example.edu')
  end

  describe 'GET /api/join/:join_code' do
    it 'responds with 404 when the join code does not exist' do
      get '/api/join/INVALID123'
      expect(response).to have_http_status(:not_found)
    end

    it 'finds the class when the code is given without a hyphen' do
      school_class # force creation before the request

      get '/api/join/B123C456'

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body, symbolize_names: true)
      expect(data[:school_class][:code]).to eq(school_class.code)
    end

    context 'when the user is not authenticated' do
      it 'returns status: unauthenticated with school and class details' do
        get "/api/join/#{school_class.join_code}"

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:status]).to eq('unauthenticated')
        expect(data[:school]).to include(code: school.code, name: school.name)
        expect(data[:school_class]).to include(code: school_class.code, name: school_class.name)
      end
    end

    context 'when the user is authenticated' do
      before { authenticated_in_hydra_as(student) }

      it 'returns status: joinable when the user can join' do
        get "/api/join/#{school_class.join_code}", headers: headers

        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:status]).to eq('joinable')
      end

      it 'returns status: already_member when the user is already in the class' do
        create(:student_role, school:, user_id: student.id)
        ClassStudent.create!(school_class:, student_id: student.id)

        get "/api/join/#{school_class.join_code}", headers: headers

        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:status]).to eq('already_member')
      end

      it 'returns status: wrong_school when the user belongs to a different school' do
        other_school = create(:school)
        create(:student_role, school: other_school, user_id: student.id)

        get "/api/join/#{school_class.join_code}", headers: headers

        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:status]).to eq('wrong_school')
      end

      it 'returns status: joinable_as_teacher when the user is a teacher of this school not yet in the class' do
        create(:teacher_role, school:, user_id: student.id)

        get "/api/join/#{school_class.join_code}", headers: headers

        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:status]).to eq('joinable_as_teacher')
      end

      it 'returns status: already_member when the user is already a teacher in the class' do
        create(:teacher_role, school:, user_id: student.id)
        ClassTeacher.create!(school_class:, teacher_id: student.id)

        get "/api/join/#{school_class.join_code}", headers: headers

        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:status]).to eq('already_member')
      end

      it 'returns status: owner when the user is an owner of this school' do
        create(:owner_role, school:, user_id: student.id)

        get "/api/join/#{school_class.join_code}", headers: headers

        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:status]).to eq('owner')
      end

      it 'returns status: not_a_student for a teacher of a different school (not wrong_school)' do
        other_school = create(:school)
        create(:teacher_role, school: other_school, user_id: student.id)

        get "/api/join/#{school_class.join_code}", headers: headers

        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:status]).to eq('not_a_student')
      end

      context 'when the email domain is not registered for the school' do
        let(:student) { create(:user, email: 'student@other.edu') }

        it 'returns status: domain_mismatch' do
          get "/api/join/#{school_class.join_code}", headers: headers

          data = JSON.parse(response.body, symbolize_names: true)
          expect(data[:status]).to eq('domain_mismatch')
        end

        it 'returns status: joinable when the user is already a student of the school' do
          create(:student_role, school:, user_id: student.id)

          get "/api/join/#{school_class.join_code}", headers: headers

          data = JSON.parse(response.body, symbolize_names: true)
          expect(data[:status]).to eq('joinable')
        end
      end
    end
  end

  describe 'POST /api/join/:join_code' do
    context 'when the user is not authenticated' do
      it 'responds with 401' do
        post "/api/join/#{school_class.join_code}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the user is authenticated' do
      before { authenticated_in_hydra_as(student) }

      it 'adds the user to the school and class and returns a redirect URL' do
        expect do
          post "/api/join/#{school_class.join_code}", headers: headers
        end.to change(ClassStudent, :count).by(1).and change(Role, :count).by(1)

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:redirect_url]).to eq("/school/#{school.code}/class/#{school_class.code}")

        created_role = Role.find_by(user_id: student.id, school:)
        expect(created_role.role).to eq('student')
      end

      it 'is idempotent when the user is already in the class' do
        create(:student_role, school:, user_id: student.id)
        ClassStudent.create!(school_class:, student_id: student.id)

        expect do
          post "/api/join/#{school_class.join_code}", headers: headers
        end.not_to change(ClassStudent, :count)

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:redirect_url]).to eq("/school/#{school.code}/class/#{school_class.code}")
      end

      it 'does not duplicate the school role if the user is already in the school' do
        create(:student_role, school:, user_id: student.id)

        expect do
          post "/api/join/#{school_class.join_code}", headers: headers
        end.to change(ClassStudent, :count).by(1)

        expect(Role.where(user_id: student.id, school:).count).to eq(1)
      end

      it 'responds with 403 wrong_school when the user belongs to a different school' do
        other_school = create(:school)
        create(:student_role, school: other_school, user_id: student.id)

        post "/api/join/#{school_class.join_code}", headers: headers

        expect(response).to have_http_status(:forbidden)
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:error]).to eq('wrong_school')
      end

      context 'when the email domain is not registered for the school' do
        let(:student) { create(:user, email: 'student@other.edu') }

        it 'responds with 403 domain_mismatch and does not enroll the user' do
          expect do
            post "/api/join/#{school_class.join_code}", headers: headers
          end.not_to change(ClassStudent, :count)

          expect(response).to have_http_status(:forbidden)
          data = JSON.parse(response.body, symbolize_names: true)
          expect(data[:error]).to eq('domain_mismatch')
        end

        it 'enrolls the user when they are already a student of the school' do
          create(:student_role, school:, user_id: student.id)

          expect do
            post "/api/join/#{school_class.join_code}", headers: headers
          end.to change(ClassStudent, :count).by(1)

          expect(response).to have_http_status(:ok)
          data = JSON.parse(response.body, symbolize_names: true)
          expect(data[:redirect_url]).to eq("/school/#{school.code}/class/#{school_class.code}")
        end
      end

      it 'adds the user to the class as a teacher and returns a redirect URL' do
        create(:teacher_role, school:, user_id: student.id)
        school_class # force creation before the request

        expect do
          post "/api/join/#{school_class.join_code}", headers: headers
        end.to change(ClassTeacher, :count).by(1)

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:redirect_url]).to eq("/school/#{school.code}/class/#{school_class.code}")
        expect(ClassTeacher.exists?(school_class:, teacher_id: student.id)).to be(true)
        expect(ClassStudent.exists?(school_class:, student_id: student.id)).to be(false)
        expect(Role.where(user_id: student.id, school:).pluck(:role)).to eq(['teacher'])
      end

      it 'is idempotent when the user is already a teacher in the class' do
        create(:teacher_role, school:, user_id: student.id)
        ClassTeacher.create!(school_class:, teacher_id: student.id)

        expect do
          post "/api/join/#{school_class.join_code}", headers: headers
        end.not_to change(ClassTeacher, :count)

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:redirect_url]).to eq("/school/#{school.code}/class/#{school_class.code}")
      end

      it 'redirects an owner into the class without adding them to it' do
        create(:owner_role, school:, user_id: student.id)

        expect do
          post "/api/join/#{school_class.join_code}", headers: headers
        end.not_to change(ClassStudent, :count)

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:redirect_url]).to eq("/school/#{school.code}/class/#{school_class.code}")
        expect(ClassTeacher.exists?(school_class:, teacher_id: student.id)).to be(false)
        expect(Role.where(user_id: student.id, school:).pluck(:role)).to eq(['owner'])
      end

      it 'responds with 404 when the join code does not exist' do
        post '/api/join/INVALID123', headers: headers
        expect(response).to have_http_status(:not_found)
      end

      # rubocop:disable RSpec/AnyInstance
      it 'responds with 500 when action_status returns an unexpected value' do
        allow_any_instance_of(Api::JoinController).to receive(:action_status).and_return(:something_unexpected)

        post "/api/join/#{school_class.join_code}", headers: headers

        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to include('Unexpected join action_status')
      end
      # rubocop:enable RSpec/AnyInstance
    end
  end
end
