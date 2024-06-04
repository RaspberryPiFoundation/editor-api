# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'mutation DeleteProject() { ... }' do
  subject(:result) { execute_query(query: mutation, variables:) }

  before do
    authenticate_as_school_owner(school_id: school.id)
  end

  let(:school) { create(:school) }
  let(:mutation) { 'mutation DeleteProject($project: DeleteProjectInput!) { deleteProject(input: $project) { id } }' }
  let(:project_id) { 'dummy-id' }
  let(:variables) { { project: { id: project_id } } }

  it { expect(mutation).to be_a_valid_graphql_query }

  context 'with an existing project' do
    let!(:project) { create(:project, user_id: stubbed_user.id) }
    let(:project_id) { project.to_gid_param }

    context 'when unauthenticated' do
      it 'does not delete a project' do
        expect { result }.not_to change(project, :name)
      end

      it 'returns an error' do
        expect(result.dig('errors', 0, 'message')).not_to be_blank
      end
    end

    context 'when the graphql context is unset' do
      let(:graphql_context) { nil }

      it 'does not delete a project' do
        expect { result }.not_to change(project, :name)
      end
    end

    context 'when authenticated' do
      let(:current_user) { stubbed_user }
      let(:school) { create(:school) }

      before do
        authenticate_as_school_owner(owner_id: stubbed_user.id, school_id: school.id)
      end

      it 'deletes the project' do
        result
        expect { project.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end

      context 'when the project cannot be found' do
        let(:project_id) { 'dummy' }

        it 'returns an error' do
          expect(result.dig('errors', 0, 'message')).to match(/not found/)
        end
      end

      context 'with another users project' do
        before do
          authenticate_as_school_teacher(school_id: school.id)
        end

        it 'returns an error' do
          expect(result.dig('errors', 0, 'message')).to match(/not permitted/)
        end
      end

      context 'when project delete fails' do
        before do
          errors = instance_double(ActiveModel::Errors, full_messages: ['An error message'])
          allow(project).to receive(:destroy).and_return(false)
          allow(project).to receive(:errors).and_return(errors)
          allow(GlobalID).to receive(:find).and_return(project)
        end

        it 'returns an error' do
          expect(result.dig('errors', 0, 'message')).to match(/Deletion failed/)
        end
      end
    end
  end
end
