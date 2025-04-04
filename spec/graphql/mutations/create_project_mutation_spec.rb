# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'mutation CreateProject() { ... }' do
  subject(:result) { execute_query(query: mutation, variables:) }

  let(:mutation) { 'mutation CreateProject($project: CreateProjectInput!) { createProject(input: $project) { project { id } } }' }
  let(:variables) do
    {
      project: {
        name: 'Untitled project',
        projectType: Project::Types::PYTHON,
        components: [{
          content: 'Insert Python Here',
          default: true,
          extension: 'py',
          name: 'main'
        }]
      }
    }
  end

  it { expect(mutation).to be_a_valid_graphql_query }

  context 'when unauthenticated' do
    it 'does not create a project' do
      expect { result }.not_to change(Project, :count)
    end

    it 'returns an error' do
      expect(result.dig('errors', 0, 'message')).not_to be_blank
    end
  end

  context 'when the graphql context is unset' do
    let(:graphql_context) { nil }

    it 'does not create a project' do
      expect { result }.not_to change(Project, :count)
    end
  end

  context 'when authenticated' do
    let(:current_user) { authenticated_user }
    let(:school) { create(:school) }
    let(:owner) { create(:owner, school:) }

    before do
      authenticated_in_hydra_as(owner)
      mock_phrase_generation
    end

    it 'returns the project ID' do
      expect(result.dig('data', 'createProject', 'project', 'id')).to eq Project.first.to_gid_param
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
