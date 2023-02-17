# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'projects { }' do
  # NB: This is mostly tested via the `project_query_spec.rb`
  subject(:result) { execute_query(query:) }

  context 'when introspecting projects' do
    let(:query) { 'query { projects { __typename } }' }

    it { expect(query).to be_a_valid_graphql_query }

    it 'returns the correct connection type' do
      expect(result.dig('data', 'projects', '__typename')).to eq 'ProjectConnection'
    end
  end

  context 'when fetching project IDs' do
    let(:query) { 'query { projects { edges { node { id } } } }' }

    it { expect(query).to be_a_valid_graphql_query }

    context 'with an unowned project' do
      let(:project) { create(:project, user_id: nil) }

      it 'returns the project global id' do
        project
        expect(result.dig('data', 'projects', 'edges', 0, 'node', 'id')).to eq project.to_gid_param
      end
    end

    context 'with an owned project' do
      let(:project) { create(:project, user_id: SecureRandom.uuid) }

      it 'returns the project global id' do
        project
        expect(result.dig('data', 'projects', 'edges')).to be_empty
      end
    end

    context 'when logged in' do
      let(:current_user_id) { SecureRandom.uuid }
      let(:project) { create(:project, user_id: current_user_id) }

      it 'returns the project global id' do
        project
        expect(result.dig('data', 'projects', 'edges', 0, 'node', 'id')).to eq project.to_gid_param
      end
    end
  end
end
