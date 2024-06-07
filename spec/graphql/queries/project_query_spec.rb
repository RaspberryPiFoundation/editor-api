# frozen_string_literal: true

require 'rails_helper'
require 'project_loader'

RSpec.describe 'query { project { ... } }' do
  subject(:result) { execute_query(query:, variables:) }

  let(:variables) { {} }

  context 'with no params' do
    let(:query) { 'query { project { id } }' }

    it { expect(query).not_to be_a_valid_graphql_query }
  end

  context 'with an identifier and locales' do
    let(:query) { 'query ($identifier: String!, $preferred_locales: [String!]) { project(identifier: $identifier, preferredLocales: $preferred_locales) { id } }' }
    let(:project) { create(:project, user_id: nil) }
    let(:variables) { { identifier: project.identifier, preferred_locales: [project.locale, 'another_locale'] } }

    it { expect(query).to be_a_valid_graphql_query }

    it 'instantiates ProjectLoader with correct arguments' do
      allow(ProjectLoader).to receive(:new).and_call_original
      result
      expect(ProjectLoader).to have_received(:new)
        .with(project.identifier, [project.locale, 'another_locale'])
    end

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
      let(:query) { 'query ($identifier: String!, $preferred_locales: [String!]) { project(identifier: $identifier, preferredLocales: $preferred_locales) { components { __typename } } }' }

      it { expect(query).to be_a_valid_graphql_query }

      it 'has the correct typename' do
        expect(result.dig('data', 'project', 'components', '__typename')).to eq 'ComponentConnection'
      end
    end

    context 'when introspecting project images' do
      let(:query) { 'query ($identifier: String!, $preferred_locales: [String!]) { project(identifier: $identifier, preferredLocales: $preferred_locales) { images { __typename } } }' }

      it { expect(query).to be_a_valid_graphql_query }

      it 'has the correct typename' do
        expect(result.dig('data', 'project', 'images', '__typename')).to eq 'ImageConnection'
      end
    end

    context 'when introspecting a remixed project parent' do
      let(:query) { 'query ($identifier: String!, $preferred_locales: [String!]) { project(identifier: $identifier, preferredLocales: $preferred_locales) { remixedFrom { __typename } } }' }
      let(:project) { create(:project, user_id: nil, parent: create(:project, user_id: nil)) }

      it { expect(query).to be_a_valid_graphql_query }

      it 'has the correct typename' do
        expect(result.dig('data', 'project', 'remixedFrom', '__typename')).to eq 'Project'
      end
    end

    context 'when the graphql context is not set' do
      let(:query_context) { nil }

      it 'returns no project' do
        expect(result.dig('data', 'project')).to be_nil
      end
    end

    context 'when logged in' do
      let(:current_user) { authenticated_user }
      let(:project) { create(:project, user_id: authenticated_user.id) }
      let(:school) { create(:school) }
      let(:owner) { create(:owner, school:) }

      before do
        authenticated_in_hydra_as(owner)
      end

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
