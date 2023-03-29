# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'mutation DeleteProject() { ... }' do
  subject(:result) { execute_query(query: mutation, variables:) }

  let(:mutation) { 'mutation DeleteProject($project: DeleteProjectInput!) { deleteProject(input: $project) { id } }' }
  let(:project_id) { 'dummy-id' }
  let(:variables) { { project: { id: project_id } } }

  shared_examples 'a no-op' do |error_code: :UNSET|
    it 'does not delete a project' do
      result
      expect { project.reload }.not_to raise_error
    end

    it 'returns an error' do
      expect(result.dig('errors', 0, 'extensions', 'code')).to eq error_code
    end
  end

  it { expect(mutation).to be_a_valid_graphql_query }

  context 'with an existing project' do
    let!(:project) { create(:project, user_id: SecureRandom.uuid) }
    let(:project_id) { project.to_gid_param }

    context 'when unauthenticated' do
      it_behaves_like 'a no-op', error_code: 'UNAUTHORIZED'
    end

    context 'when the graphql context is unset' do
      let(:graphql_context) { nil }

      it_behaves_like 'a no-op', error_code: 'UNAUTHORIZED'
    end

    context 'when authenticated' do
      let(:current_user_id) { project.user_id }

      it 'deletes the project' do
        result
        expect { project.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end

      context 'when the user is not allowed to delete projects' do
        before do
          ability = instance_double(Ability, can?: false)
          allow(Ability).to receive(:new).and_return(ability)
        end

        it_behaves_like 'a no-op', error_code: 'FORBIDDEN'
      end

      context 'when the project cannot be found' do
        let(:project_id) { 'dummy' }

        it_behaves_like 'a no-op', error_code: 'NOT_FOUND'
      end

      context 'with another users project' do
        let(:current_user_id) { SecureRandom.uuid }

        it_behaves_like 'a no-op', error_code: 'FORBIDDEN'
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
