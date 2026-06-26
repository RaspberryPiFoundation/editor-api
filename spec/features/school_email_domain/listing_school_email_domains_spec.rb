# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Listing school email domains', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:school_email_domains) { create_list(:school_email_domain, 5, school: school) }

  before do
    school_email_domains
  end

  describe '#index' do
    shared_examples 'a successful school email domains index' do
      it 'responds 200 OK' do
        expect(response).to have_http_status(:ok)
      end

      context 'when the school has domains' do
        it 'returns a list of domains for the school' do
          data = JSON.parse(response.body, symbolize_names: true)
          expect(data).to match_array(school.school_email_domains.pluck(:domain))
        end
      end

      context 'when domains do not belong to the school' do
        let(:other_school) { create(:school) }
        let(:school_email_domains) { create_list(:school_email_domain, 5, school: other_school) }

        it 'returns an empty array' do
          data = JSON.parse(response.body, symbolize_names: true)
          expect(data).to eq([])
        end
      end
    end

    context 'with an authorised owner' do
      let(:owner) { create(:owner, school:, name: 'School Owner') }

      before do
        authenticated_in_hydra_as(owner)
        get("/api/schools/#{school.id}/school_email_domains", headers:)
      end

      it_behaves_like 'a successful school email domains index'
    end

    context 'with an authorised teacher' do
      let(:teacher) { create(:teacher, school:, name: 'School Teacher') }

      before do
        authenticated_in_hydra_as(teacher)
        get("/api/schools/#{school.id}/school_email_domains", headers:)
      end

      it_behaves_like 'a successful school email domains index'
    end

    context 'when the user does not have access' do
      it 'responds 403 Forbidden when the user is a school-owner for a different school' do
        other_school = create(:school)
        other_owner = create(:owner, school: other_school, name: 'School Owner')
        authenticated_in_hydra_as(other_owner)

        get("/api/schools/#{school.id}/school_email_domains", headers:)
        expect(response).to have_http_status(:forbidden)
      end

      it 'responds 403 Forbidden when the user is a school-teacher for a different school' do
        other_school = create(:school)
        other_teacher = create(:teacher, school: other_school, name: 'School Teacher')
        authenticated_in_hydra_as(other_teacher)

        get("/api/schools/#{school.id}/school_email_domains", headers:)
        expect(response).to have_http_status(:forbidden)
      end

      it 'responds 403 Forbidden when the user is a student at the school' do
        student = create(:student, school:)
        authenticated_in_hydra_as(student)

        get("/api/schools/#{school.id}/school_email_domains", headers:)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when the user is not authenticated' do
      it 'responds 401 Unauthorized when no token is given' do
        get "/api/schools/#{school.id}/school_email_domains"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
