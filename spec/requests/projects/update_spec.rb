# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project update requests' do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }

  context 'when authed user is project creator' do
    let!(:project) { create(:project, :with_default_component, user_id: owner.id, locale: nil) }
    let!(:component) { create(:component, project:) }
    let(:default_component_params) do
      project.components.first.attributes.symbolize_keys.slice(
        :id,
        :name,
        :content,
        :extension
      )
    end
    let(:owner) { create(:owner, school:) }
    let(:school) { create(:school) }

    let(:params) do
      { project:
        {
          components: [
            default_component_params,
            { id: component.id, name: 'updated', extension: 'py', content: 'updated component content' }
          ]
        } }
    end

    before do
      authenticated_in_hydra_as(owner)
    end

    it 'returns success response' do
      put("/api/projects/#{project.identifier}", params:, headers:)
      expect(response).to have_http_status(:ok)
    end

    it 'returns updated project json' do
      put("/api/projects/#{project.identifier}", params:, headers:)
      expect(response.body).to include('updated component content')
    end

    it 'calls update operation' do
      mock_response = instance_double(OperationResponse)
      allow(mock_response).to receive(:success?).and_return(true)
      allow(Project::Update).to receive(:call).and_return(mock_response)
      put("/api/projects/#{project.identifier}", params:, headers:)
      expect(Project::Update).to have_received(:call)
    end

    context 'when no components specified' do
      let(:params) { { project: { name: 'updated project name' } } }

      it 'returns success response' do
        put("/api/projects/#{project.identifier}", params:, headers:)
        expect(response).to have_http_status(:ok)
      end

      it 'returns json with updated project name' do
        put("/api/projects/#{project.identifier}", params:, headers:)
        expect(response.body).to include('updated project name')
      end

      it 'returns json with previous project components' do
        put("/api/projects/#{project.identifier}", params:, headers:)
        expect(response.body).to include(project.components.first.attributes[:content].to_s)
      end
    end

    context 'when updated project has no components' do
      let(:params) { { project: { components: [] } } }

      it 'returns error response' do
        put("/api/projects/#{project.identifier}", params:, headers:)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when updated (non-school) project has instructions' do
      let(:params) { { project: { instructions: 'updated instructions' } } }

      it 'returns error response' do
        put("/api/projects/#{project.identifier}", params:, headers:)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  context 'when authed user is not creator' do
    let(:project) { create(:project, locale: nil) }
    let(:params) { { project: { components: [] } } }
    let(:school) { create(:school) }
    let(:owner) { create(:owner, school:) }

    before do
      authenticated_in_hydra_as(owner)
    end

    it 'returns forbidden response' do
      put("/api/projects/#{project.identifier}", params:, headers:)
      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'when authed user is a teacher' do
    let(:project) { create(:project, :with_instructions, school:, locale: nil, user_id: teacher.id) }
    let(:params) { { project: { components: [], instructions: 'updated instructions' } } }
    let(:school) { create(:school) }
    let(:teacher) { create(:teacher, school:) }

    before do
      authenticated_in_hydra_as(teacher)
    end

    it 'returns success when instructions updated' do
      put("/api/projects/#{project.identifier}", params:, headers:)
      expect(response).to have_http_status(:ok)
    end

    it 'includes updated instructions in response' do
      put("/api/projects/#{project.identifier}", params:, headers:)
      expect(response.body).to include('updated instructions')
    end
  end

  context 'when authed user is a student and the project is remixed from a lesson project' do
    let(:teacher) { create(:teacher, school:) }
    let(:lesson_project) { create(:project, school:, locale: nil, user_id: teacher.id, lesson: create(:lesson, visibility: "students")) }
    let(:project) { create(:project, school:, locale: nil, user_id: student.id, remixed_from_id: lesson_project.id) }
    let(:params) { { project: { components: [] } } }
    let(:school) { create(:school) }
    let(:student) { create(:student, school:) }

    before do
      authenticated_in_hydra_as(student)
    end

    it 'returns success if instructions not updated' do
      put("/api/projects/#{project.identifier}", params:, headers:)
      expect(response).to have_http_status(:ok)
    end

    it 'returns unprocessable entity if instructions updated' do
      params[:project][:instructions] = 'updated instructions'
      put("/api/projects/#{project.identifier}", params:, headers:)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context 'when auth token is invalid' do
    let(:project) { create(:project) }

    before do
      unauthenticated_in_hydra
    end

    it 'returns unauthorized' do
      put("/api/projects/#{project.identifier}", headers:)

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
