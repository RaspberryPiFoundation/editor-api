# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'mutation UpdateProject() { ... }' do
  subject(:result) { execute_query(query: mutation, variables:) }

  before do
    authenticate_as_school_owner(school_id: SecureRandom.uuid)
  end

  let(:mutation) { 'mutation UpdateProject($project: UpdateProjectInput!) { updateProject(input: $project) { project { id } } }' }
  let(:project_id) { 'dummy-id' }
  let(:variables) do
    {
      project: {
        id: project_id,
        name: 'Untitled project again',
        projectType: 'html'
      }
    }
  end

  it { expect(mutation).to be_a_valid_graphql_query }

  context 'with an existing project' do
    let(:project) { create(:project, user_id: stubbed_user.id, project_type: :python) }
    let(:project_id) { project.to_gid_param }

    before do
      # Instantiate project
      project
      authenticate_as_school_owner(owner_id: stubbed_user.id, school_id: SecureRandom.uuid)
    end

    context 'when unauthenticated' do
      it 'does not update a project' do
        expect { result }.not_to change(project, :name)
      end

      it 'returns an error' do
        expect(result.dig('errors', 0, 'message')).not_to be_blank
      end
    end

    context 'when the graphql context is unset' do
      let(:graphql_context) { nil }

      it 'does not update a project' do
        expect { result }.not_to change(project, :name)
      end
    end

    context 'when authenticated' do
      let(:current_user) { stubbed_user }

      it 'updates the project name' do
        expect { result }.to change { project.reload.name }.from(project.name).to(variables.dig(:project, :name))
      end

      it 'updates the project type' do
        expect { result }.to change { project.reload.project_type }.from(project.project_type).to('html')
      end

      context 'when the project cannot be found' do
        let(:project_id) { 'dummy' }

        it 'returns an error' do
          expect(result.dig('errors', 0, 'message')).to match(/not found/)
        end
      end

      context 'with another users project' do
        before do
          authenticate_as_school_teacher(school_id: SecureRandom.uuid)
        end

        it 'returns an error' do
          expect(result.dig('errors', 0, 'message')).to match(/not permitted/)
        end
      end

      context 'when project update fails' do
        before do
          errors = instance_double(ActiveModel::Errors, full_messages: ['An error message'])
          allow(project).to receive(:save).and_return(false)
          allow(project).to receive(:errors).and_return(errors)
          allow(GlobalID).to receive(:find).and_return(project)
        end

        it 'returns an error' do
          expect(result.dig('errors', 0, 'message')).to match(/An error message/)
        end
      end
    end
  end
end
