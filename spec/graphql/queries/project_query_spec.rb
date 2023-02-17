# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'query { project { ... } }' do
  subject(:result) { execute_query(query:, variables:) }

  let(:variables) { {} }

  context 'with no params' do
    let(:query) { 'query { project { id } }' }

    it { expect(query).not_to be_a_valid_graphql_query }
  end

  context 'with an identifier' do
    let(:query) { 'query ($identifier: String!) { project(identifier: $identifier) { id } }' }
    let(:project) { create(:project, user_id: nil) }
    let(:variables) { { identifier: project.identifier } }

    it { expect(query).to be_a_valid_graphql_query }

    it 'returns the project global id' do
      expect(result.dig('data', 'project', 'id')).to eq project.to_gid_param
    end

    context 'with a unknown id' do
      let(:variables) { { identifier: 'kittens' } }

      it 'returns no project' do
        expect(result.dig('data', 'project')).to be_nil
      end
    end

    context 'when the project is owned by someone else' do
      let(:project) { create(:project, user_id: SecureRandom.uuid) }

      it 'returns no projects' do
        expect(result.dig('data', 'project')).to be_nil
      end
    end

    context 'when introspecting project components' do
      let(:query) { 'query ($identifier: String!) { project(identifier: $identifier) { components { __typename } } }' }

      it { expect(query).to be_a_valid_graphql_query }

      it 'has the correct typename' do
        expect(result.dig('data', 'project', 'components', '__typename')).to eq 'ComponentConnection'
      end
    end

    context 'when introspecting project images' do
      let(:query) { 'query ($identifier: String!) { project(identifier: $identifier) { images { __typename } } }' }

      it { expect(query).to be_a_valid_graphql_query }

      it 'has the correct typename' do
        expect(result.dig('data', 'project', 'images', '__typename')).to eq 'ImageConnection'
      end
    end

    context 'when introspecting a remixed project parent' do
      let(:query) { 'query ($identifier: String!) { project(identifier: $identifier) { remixedFrom { __typename } } }' }
      let(:project) { create(:project, user_id: nil, parent: create(:project, user_id: nil)) }

      it { expect(query).to be_a_valid_graphql_query }

      it 'has the correct typename' do
        expect(result.dig('data', 'project', 'remixedFrom', '__typename')).to eq 'Project'
      end
    end

    context 'when the graphql context is not set' do
      let(:graphql_context) { nil }

      it 'returns no projects' do
        expect(result.dig('data', 'project')).to be_nil
      end
    end

    context 'when logged in' do
      let(:current_user_id) { SecureRandom.uuid }
      let(:project) { create(:project, user_id: current_user_id) }

      it 'returns the project global id' do
        expect(result.dig('data', 'project', 'id')).to eq project.to_gid_param
      end

      context 'when the project is owned by someone else' do
        let(:project) { create(:project, user_id: SecureRandom.uuid) }

        it 'returns no projects' do
          expect(result.dig('data', 'project')).to be_nil
        end
      end
    end
  end
end
