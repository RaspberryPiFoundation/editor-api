# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'mutation CreateProject() { ... }' do
  subject(:result) { execute_query(query: mutation, variables:) }

  let(:mutation) { 'mutation CreateProject($project: CreateProjectInput!) { createProject(input: $project) { project { id } } }' }
  let(:variables) do
    {
      project: {
        name: 'Untitled project',
        projectType: 'python',
        components: [{
          content: 'Insert Python Here',
          default: true,
          extension: 'py',
          name: 'main'
        }]
      }
    }
  end

  shared_examples 'a no-op' do |error_code: 'UNSET'|
    it 'does not create a project' do
      expect { result }.not_to change(Project, :count)
    end

    it 'returns an error' do
      expect(result.dig('errors', 0, 'extensions', 'code')).to eq error_code
    end
  end

  it { expect(mutation).to be_a_valid_graphql_query }

  context 'when unauthenticated' do
    it_behaves_like 'a no-op', error_code: 'UNAUTHORIZED'
  end

  context 'when the graphql context is unset' do
    let(:graphql_context) { nil }

    it_behaves_like 'a no-op', error_code: 'UNAUTHORIZED'
  end

  context 'when authenticated' do
    let(:current_user_id) { SecureRandom.uuid }

    before { mock_phrase_generation }

    it 'returns the project ID' do
      expect(result.dig('data', 'createProject', 'project', 'id')).to eq Project.first.to_gid_param
    end

    context 'when the user is not allowed to create projects' do
      before do
        ability = instance_double(Ability, can?: false)
        allow(Ability).to receive(:new).and_return(ability)
      end

      it_behaves_like 'a no-op', error_code: 'FORBIDDEN'
    end

    context 'when project creation fails' do
      before do
        allow(Project::Create).to receive(:call).and_return(OperationResponse[error: 'Foo'])
      end

      it 'returns an error' do
        expect(result.dig('errors', 0, 'message')).to eq 'Foo'
      end
    end
  end
end
