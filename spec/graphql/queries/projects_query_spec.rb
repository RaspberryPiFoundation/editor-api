# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'projects { }' do
  # NB: This is mostly tested via the `project_query_spec.rb`
  subject(:result) { execute_query(query:, variables:) }

  let(:current_user) { nil }
  let(:variables) { {} }

  context 'when introspecting projects' do
    let(:query) { 'query { projects { __typename } }' }

    it { expect(query).to be_a_valid_graphql_query }

    it 'returns the correct connection type' do
      expect(result.dig('data', 'projects', '__typename')).to eq 'ProjectConnection'
    end
  end

  context 'when fetching projects without auth' do
    let(:query) { 'query { projects { edges { node { id } } } }' }

    it { expect(query).to be_a_valid_graphql_query }

    context 'with an existing unowned project' do
      let(:project) { create(:project, user_id: nil) }

      it 'returns the project global id' do
        project
        expect(result.dig('data', 'projects', 'edges', 0, 'node', 'id')).to eq project.to_gid_param
      end
    end

    context 'with an existing owned project' do
      let(:project) { create(:project, user_id: SecureRandom.uuid) }

      it 'returns an empty array' do
        project
        expect(result.dig('data', 'projects', 'edges')).to be_empty
      end
    end
  end

  context 'when fetching project when logged in' do
    let(:query) { 'query { projects { edges { node { id } } } }' }
    let(:current_user) { stubbed_user }
    let(:project) { create(:project, user_id: stubbed_user.id) }
    let(:school) { create(:school) }

    before do
      authenticate_as_school_owner(school:, owner_id: SecureRandom.uuid)
    end

    it { expect(query).to be_a_valid_graphql_query }

    context 'with an existing project owned by the user' do
      it 'returns the project global id' do
        project
        expect(result.dig('data', 'projects', 'edges', 0, 'node', 'id')).to eq project.to_gid_param
      end
    end

    context 'with an existing unowned project' do
      let(:project) { create(:project, user_id: nil) }

      it 'returns the project global id' do
        project
        expect(result.dig('data', 'projects', 'edges', 0, 'node', 'id')).to eq project.to_gid_param
      end
    end

    context 'with an existing project owned by someone else' do
      let(:project) { create(:project, user_id: SecureRandom.uuid) }

      it 'returns an empty array' do
        project
        expect(result.dig('data', 'projects', 'edges')).to be_empty
      end
    end
  end

  context 'when fetching projects by user ID when logged in' do
    let(:query) { 'query ($userId: String) { projects(userId: $userId) { edges { node { id } } } }' }
    let(:current_user) { stubbed_user }
    let(:variables) { { userId: stubbed_user.id } }
    let(:project) { create(:project, user_id: stubbed_user.id) }
    let(:school) { create(:school) }

    before do
      authenticate_as_school_owner(school:, owner_id: SecureRandom.uuid)
    end

    it { expect(query).to be_a_valid_graphql_query }

    context 'with an existing project owned by the user' do
      it 'returns the project global id' do
        project
        expect(result.dig('data', 'projects', 'edges', 0, 'node', 'id')).to eq project.to_gid_param
      end
    end

    context 'with an existing unowned project' do
      let(:project) { create(:project, user_id: nil) }

      it 'returns an empty array' do
        project
        expect(result.dig('data', 'projects', 'edges')).to be_empty
      end
    end

    context 'with an existing project owned by someone else' do
      let(:project) { create(:project, user_id: SecureRandom.uuid) }

      it 'returns an empty array' do
        project
        expect(result.dig('data', 'projects', 'edges')).to be_empty
      end
    end
  end
end
