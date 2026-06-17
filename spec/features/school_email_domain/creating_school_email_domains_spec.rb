# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating school email domains', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:school) { create(:school) }
  let(:domain) { 'school.edu' }
  let(:params) do
    {
      school_email_domain: {
        domain:
      }
    }
  end
  let(:owner) { create(:owner, school:, name: 'School Owner') }

  before { stub_profile_api_update_school_email_domains }

  describe '#create' do
    shared_examples 'a successful school email domain creation response' do
      it 'responds 201 created' do
        expect(response).to have_http_status(:created)
      end

      it 'creates the domain' do
        expect(SchoolEmailDomain.exists?(school:, domain:)).to be(true)
      end

      it 'returns the domain' do
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:domain]).to eq(domain)
      end
    end

    shared_examples 'an unprocessable school email domain creation response' do
      before do
        authenticated_in_hydra_as(owner)
        post("/api/schools/#{school.id}/school_email_domains", headers:, params:)
      end

      it 'responds 422 Unprocessable Entity' do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns the error in the response body' do
        data = JSON.parse(response.body, symbolize_names: true)
        expect(data[:error]).to match(expected_error)
      end
    end

    context 'with an authorised owner' do
      before do
        authenticated_in_hydra_as(owner)
        post("/api/schools/#{school.id}/school_email_domains", headers:, params:)
      end

      it_behaves_like 'a successful school email domain creation response'
    end

    context 'with an authorised teacher' do
      let(:teacher) { create(:teacher, school:, name: 'School Teacher') }

      before do
        authenticated_in_hydra_as(teacher)
        post("/api/schools/#{school.id}/school_email_domains", headers:, params:)
      end

      it_behaves_like 'a successful school email domain creation response'
    end

    context 'with missing params' do
      it 'responds 400 Bad Request when params are missing' do
        authenticated_in_hydra_as(owner)

        post("/api/schools/#{school.id}/school_email_domains", headers:)

        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when the user does not have access' do
      it 'responds 403 Forbidden when the user is a school-owner for a different school' do
        other_school = create(:school)
        other_owner = create(:owner, school: other_school, name: 'School Owner')
        authenticated_in_hydra_as(other_owner)

        post("/api/schools/#{school.id}/school_email_domains", headers:, params:)
        expect(response).to have_http_status(:forbidden)
      end

      it 'responds 403 Forbidden when the user is a school-teacher for a different school' do
        other_school = create(:school)
        other_teacher = create(:teacher, school: other_school, name: 'School Teacher')
        authenticated_in_hydra_as(other_teacher)

        post("/api/schools/#{school.id}/school_email_domains", headers:, params:)
        expect(response).to have_http_status(:forbidden)
      end

      it 'responds 403 Forbidden when the user is a student at the school' do
        student = create(:student, school:)
        authenticated_in_hydra_as(student)

        post("/api/schools/#{school.id}/school_email_domains", headers:, params:)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when the user is not authenticated' do
      it 'responds 401 Unauthorized when no token is given' do
        post "/api/schools/#{school.id}/school_email_domains"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the domain cannot be processed' do
      context 'when the domain is blank' do
        let(:domain) { '' }
        let(:expected_error) { /Domain can't be blank/ }

        it_behaves_like 'an unprocessable school email domain creation response'

        it 'does not create a school email domain' do
          authenticated_in_hydra_as(owner)
          post("/api/schools/#{school.id}/school_email_domains", headers:, params:)
          expect(SchoolEmailDomain.where(school:)).to be_none
        end
      end

      context 'when the domain is not an FQDN' do
        let(:domain) { 'edu' }
        let(:expected_error) { /Domain must be a fully qualified domain name/ }

        it_behaves_like 'an unprocessable school email domain creation response'

        it 'does not create a school email domain' do
          authenticated_in_hydra_as(owner)
          post("/api/schools/#{school.id}/school_email_domains", headers:, params:)
          expect(SchoolEmailDomain.where(school:)).to be_none
        end
      end

      context 'when the uri is invalid' do
        let(:domain) { 'exa mple.com' }
        let(:expected_error) { /Domain must be a valid domain format/ }

        it_behaves_like 'an unprocessable school email domain creation response'

        it 'does not create a school email domain' do
          authenticated_in_hydra_as(owner)
          post("/api/schools/#{school.id}/school_email_domains", headers:, params:)
          expect(SchoolEmailDomain.where(school:)).to be_none
        end
      end

      context 'when the public suffix is invalid' do
        let(:domain) { 'co.uk' }
        let(:expected_error) { /Domain must be a registrable domain name/ }

        it_behaves_like 'an unprocessable school email domain creation response'

        it 'does not create a school email domain' do
          authenticated_in_hydra_as(owner)
          post("/api/schools/#{school.id}/school_email_domains", headers:, params:)
          expect(SchoolEmailDomain.where(school:)).to be_none
        end
      end

      context 'when the domain is a duplicate' do
        let(:expected_error) { /Domain has already been taken/ }

        before do
          create(:school_email_domain, school:, domain:)
        end

        it_behaves_like 'an unprocessable school email domain creation response'

        it 'does not create a duplicate school email domain' do
          authenticated_in_hydra_as(owner)
          post("/api/schools/#{school.id}/school_email_domains", headers:, params:)
          expect(SchoolEmailDomain.where(school:, domain:).count).to eq(1)
        end
      end
    end

    context 'when Profile sync fails' do
      let(:profile_error) do
        ProfileApiClient::UnexpectedResponse.new(
          instance_double(Faraday::Response, status: 500, headers: {}, body: '')
        )
      end
      let(:expected_error) { /Unexpected response from Profile API \(status code 500\)/ }

      before do
        allow(ProfileApiClient).to receive(:update_school_email_domains).and_raise(profile_error)
      end

      it_behaves_like 'an unprocessable school email domain creation response'

      it 'does not persist the domain' do
        authenticated_in_hydra_as(owner)
        post("/api/schools/#{school.id}/school_email_domains", headers:, params:)

        expect(SchoolEmailDomain.exists?(school:, domain:)).to be(false)
      end
    end
  end
end
